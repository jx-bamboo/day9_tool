class TokenMetadataService
  class NotErc20 < StandardError; end

  def initialize(contract_address)
    @contract_address = contract_address
  end

  def fetch
    client = BalanceService.client

    meta = try_standard(client)
    meta ||= try_bytes32(client)

    raise NotErc20, "无法读取该合约的元数据，可能不是 ERC-20" if meta.nil?
    meta
  end

  private

  def try_standard(client)
    contract = Eth::Contract.from_abi(
      abi: Erc20Abi::STANDARD.to_json,
      address: @contract_address,
      name: "ERC20"
    )

    {
      name:     normalize_string(client.call(contract, "name")),
      symbol:   normalize_string(client.call(contract, "symbol")),
      decimals: client.call(contract, "decimals").to_i
    }
  rescue Eth::Client::ContractExecutionError, Eth::Contract::Error, IOError => e
    Rails.logger.info("[TokenMetadata] standard failed: #{e.class}: #{e.message}")
    nil
  end

  def try_bytes32(client)
    contract = Eth::Contract.from_abi(
      abi: Erc20Abi::BYTES32_METADATA.to_json,
      address: @contract_address,
      name: "ERC20Legacy"
    )

    {
      name:     normalize_string(client.call(contract, "name")),
      symbol:   normalize_string(client.call(contract, "symbol")),
      decimals: client.call(contract, "decimals").to_i
    }
  rescue Eth::Client::ContractExecutionError, Eth::Contract::Error, IOError => e
    Rails.logger.info("[TokenMetadata] bytes32 failed: #{e.class}: #{e.message}")
    nil
  end

  # 把 eth.rb 返回的 ASCII-8BIT 字节串转成合法 UTF-8
  def normalize_string(raw)
    return nil if raw.nil?
    s = raw.to_s.dup
    s.force_encoding(Encoding::UTF_8)

    # 无法解码的字节替换成 �，不抛异常
    s = s.scrub("?") unless s.valid_encoding?

    # bytes32 类型返回的字符串尾部带 \x00，去掉
    s.gsub("\x00", "").strip
  end
end
