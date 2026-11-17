class DistributionJob < ApplicationJob
  queue_as :default

  GAS_LIMIT_NATIVE = 21_000
  GAS_LIMIT_ERC20  = 80_000
  GAS_BUFFER_RATIO = 1.5
  RECEIPT_TIMEOUT  = 120

  def perform(batch_id, user_id)
    transfers = Transfer.for_batch(batch_id).pending.to_a
    return if transfers.empty?

    from_address = transfers.first.from_address
    token        = transfers.first.token
    user         = User.find_by(id: user_id)

    # 1. 密码检查
    password = Rails.cache.read("dispatch_pwd:#{batch_id}")
    unless password
      return fail_all!(transfers, "执行密码已过期，请重新提交")
    end

    # 2. 解密私钥
    key = begin
      WalletService.decrypt(from_address.keystore, password)
    rescue WalletService::InvalidPassword
      return fail_all!(transfers, "执行密码错误")
    end

    # 3. 余额预检查
    client    = BalanceService.client
    gas_price = rpc_int(client.eth_gas_price)

    check = check_balance(client, from_address, token, transfers, gas_price)
    unless check[:ok]
      return fail_all!(transfers, check[:reason])
    end

    AuditService.log!(
      action: "dispatch_started",
      user: user,
      auditable: from_address,
      metadata: { batch_id: batch_id, count: transfers.count, token: token.symbol, gas_price: gas_price }
    )

    # ========================================================
    # 阶段一：批量广播所有交易（尽快塞进 mempool）
    # ========================================================
    nonce         = rpc_int(client.get_nonce(from_address.address))
    halted_reason = nil
    broadcasted   = []   # [[transfer, tx_hash], ...]

    transfers.each do |transfer|
      if halted_reason
        transfer.update!(status: :failed, error_message: "批次已中止：#{halted_reason}")
        next
      end

      while Rails.cache.read("dispatch_paused:#{batch_id}")
        sleep 2
      end

      begin
        transfer.update!(status: :broadcasting, broadcasted_at: Time.current)

        tx_hash = broadcast_one(client, key, transfer, nonce, gas_price)
        raise "节点未返回交易哈希" if tx_hash.blank?

        nonce += 1
        transfer.update!(tx_hash: tx_hash)
        broadcasted << [ transfer, tx_hash ]

        # 广播间隔 200ms，避免瞬时打爆 RPC 限流
        sleep 0.2

      rescue => e
        msg = e.message.to_s
        Rails.logger.error("[DistributionJob][broadcast] transfer=#{transfer.id} #{e.class}: #{msg}")
        transfer.update!(status: :failed, error_message: "广播失败：#{msg[0, 480]}")

        # 致命错误（余额不足、nonce 异常）→ 剩余全部中止
        halted_reason = msg[0, 200] if fatal_error?(msg)
      end
    end

    # ========================================================
    # 阶段二：统一等待回执（并发轮询）
    # ========================================================
    # 所有交易已在 mempool 里排队，这里只是等确认
    # 用简单的时间片轮询，每轮检查所有 pending 的 tx
    pending_map = broadcasted.to_h { |transfer, tx_hash| [ tx_hash, transfer ] }
    deadline    = Time.current + RECEIPT_TIMEOUT

    until pending_map.empty? || Time.current > deadline
      still_pending = {}

      pending_map.each do |tx_hash, transfer|
        begin
          raw     = client.eth_get_transaction_receipt(tx_hash)
          receipt = raw.is_a?(Hash) ? raw["result"] : raw

          if receipt.is_a?(Hash) && (receipt["blockNumber"].present? || receipt["blockHash"].present?)
            if receipt_status(receipt) == 1
              transfer.update!(status: :confirmed, confirmed_at: Time.current)
            else
              transfer.update!(status: :failed, error_message: "链上执行 reverted")
            end
          else
            still_pending[tx_hash] = transfer
          end
        rescue => e
          Rails.logger.warn("[DistributionJob][receipt] tx=#{tx_hash} #{e.class}: #{e.message}")
          still_pending[tx_hash] = transfer   # 单次查询失败不算超时，下一轮再试
        end
      end

      pending_map = still_pending
      break if pending_map.empty?
      sleep 3
    end

    # 超时未确认的，标记 failed
    pending_map.each do |tx_hash, transfer|
      transfer.update!(
        status: :failed,
        error_message: "等待链上确认超时（#{RECEIPT_TIMEOUT}s）：tx=#{tx_hash[0, 12]}…"
      )
    end

    AuditService.log!(
      action: "dispatch_finished",
      user: user,
      auditable: from_address,
      metadata: { batch_id: batch_id, summary: Transfer.batch_summary(batch_id) }
    )
  ensure
    Rails.cache.delete("dispatch_pwd:#{batch_id}")
    Rails.cache.delete("dispatch_paused:#{batch_id}")
  end

  private

  # ========== RPC 返回值统一提取 ==========
  def rpc_hex(raw)
    raw.is_a?(Hash) ? (raw["result"] || raw[:result]) : raw
  end

  def rpc_int(raw)
    hex = rpc_hex(raw)
    return 0 if hex.nil?
    hex.is_a?(String) ? hex.to_i(16) : hex.to_i
  end

  # ========== 余额预检查 ==========
  def check_balance(client, from_address, token, transfers, gas_price)
    bnb_wei = rpc_int(client.get_balance(from_address.address))   # ← 修复

    per_tx_gas   = token.native? ? GAS_LIMIT_NATIVE : GAS_LIMIT_ERC20
    total_gas    = per_tx_gas * transfers.count
    gas_cost_wei = (total_gas * gas_price * GAS_BUFFER_RATIO).to_i

    required_wei =
      if token.native?
        gas_cost_wei + transfers.sum(&:amount).to_i
      else
        gas_cost_wei
      end

    if bnb_wei < required_wei
      {
        ok: false,
        reason: "分发地址 BNB 余额不足：当前 #{fmt_bnb(bnb_wei)} BNB，" \
                "需要约 #{fmt_bnb(required_wei)} BNB（转账金额 + gas 及缓冲）"
      }
    else
      { ok: true }
    end
  end

  # ========== 广播单笔 ==========
  def broadcast_one(client, key, transfer, nonce, gas_price)
    chain_id = transfer.token.chain_id || 56

    tx =
      if transfer.token.native?
        Eth::Tx.new(
          from:      key.address.to_s,
          to:        transfer.to_address.address,
          value:     transfer.amount.to_i,
          data:      "0x",
          gas_limit: GAS_LIMIT_NATIVE,
          gas_price: gas_price,
          nonce:     nonce,
          chain_id:  chain_id
        )
      else
        Eth::Tx.new(
          from:      key.address.to_s,
          to:        transfer.token.contract_address,
          value:     0,
          data:      erc20_transfer_data(transfer.to_address.address, transfer.amount.to_i),
          gas_limit: GAS_LIMIT_ERC20,
          gas_price: gas_price,
          nonce:     nonce,
          chain_id:  chain_id
        )
      end

    tx.sign(key)
    signed_hex = "0x#{tx.encoded.unpack1('H*')}"
    rpc_hex(client.eth_send_raw_transaction(signed_hex))
  end

  def erc20_transfer_data(to_address, amount_wei)
    "0xa9059cbb" \
      "#{to_address.sub(/\A0x/, '').downcase.rjust(64, '0')}" \
      "#{amount_wei.to_i.to_s(16).rjust(64, '0')}"
  end

  # ========== 回执轮询 ==========
  def wait_for_receipt(client, tx_hash, timeout = 120)
    deadline = Time.current + timeout
    while Time.current < deadline
      raw = client.eth_get_transaction_receipt(tx_hash)

      # ★ 提取内层 result（交易未上链时 result 是 nil）
      receipt = raw.is_a?(Hash) ? raw["result"] : raw

      if receipt.is_a?(Hash) && (receipt["blockNumber"].present? || receipt["blockHash"].present?)
        return receipt
      end

      sleep 3
    end
    nil
  end

  def receipt_present?(receipt)
    return false if receipt.nil?
    if receipt.respond_to?(:block_number)
      receipt.block_number.present?
    elsif receipt.is_a?(Hash)
      (receipt["blockNumber"] || receipt[:blockNumber]).present?
    else
      true
    end
  end

  def receipt_status(receipt)
    # receipt 可能是内层 Hash 或外层包装，兼容处理
    inner = receipt.is_a?(Hash) && receipt["result"].is_a?(Hash) ? receipt["result"] : receipt
    raw = inner["status"] || inner[:status]
    return 1 if raw.nil?
    raw.is_a?(String) ? raw.to_i(16) : raw.to_i
  end

  # ========== 致命错误判断 ==========
  def fatal_error?(msg)
    msg.match?(/insufficient funds|nonce too low|replacement transaction underpriced|intrinsic gas too low/i)
  end

  # ========== 工具 ==========
  def fail_all!(transfers, reason)
    transfers.each { |t| t.update!(status: :failed, error_message: reason) }
    Rails.logger.warn("[DistributionJob] batch failed: #{reason}")
  end

  def fmt_bnb(wei)
    (BigDecimal(wei.to_s) / BigDecimal("1e18")).round(6).to_s("F")
  end
end
