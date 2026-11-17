class BalanceService
  api_key = Rails.application.credentials.dig(:infura, :api_key_test)
  raise "Infura API key 未配置（production credentials）" if api_key.blank?

  NETWORK = Rails.env.production? ? "bsc-mainnet" : "bsc-testnet"
  INFURA_URL = "https://#{NETWORK}.infura.io/v3/#{api_key}".freeze

  class << self
    def client
      @client ||= Eth::Client.create(INFURA_URL)
    end

    def fetch_bnb(address)
      wei = client.get_balance(address)
      wei_to_display(wei)
    rescue => e
      Rails.logger.error("[BalanceService] fetch_bnb #{address}: #{e.class}: #{e.message}")
      raise
    end

    def fetch_token(address, token)
      data = "0x70a08231#{address.sub(/\A0x/, '').rjust(64, '0')}"
      raw  = client.eth_call({ to: token.contract_address, data: data })

      # eth.rb 不同版本返回 String 或 Hash，统一处理
      hex =
        if raw.is_a?(Hash)
          raw["result"] || raw[:result]
        else
          raw.to_s
        end

      if hex.blank? || hex == "0x"
        Rails.logger.warn(
          "[BalanceService] token #{token.symbol} (#{token.contract_address}) " \
          "returned empty 0x — 合约地址可能不是 BEP-20 合约"
        )
        return BigDecimal("0")
      end

      wei_to_display(hex.to_i(16), token.decimals)
    rescue => e
      Rails.logger.error("[BalanceService] fetch_token #{address}/#{token.symbol}: #{e.class}: #{e.message}")
      raise
    end

    def refresh_address!(record, tokens: Token.active)
      bnb = begin
        fetch_bnb(record.address)
      rescue => e
        Rails.logger.error("[BalanceService] refresh bnb #{record.address}: #{e.message}")
        record.update!(balance_checked_at: Time.current)
        return false
      end

      balances = {}
      tokens.bep20.each do |token|
        balances[token.symbol] = begin
          fetch_token(record.address, token).to_s("F")
        rescue => e
          Rails.logger.error("[BalanceService] refresh token #{record.address}/#{token.symbol}: #{e.message}")
          "0"
        end
      end

      record.update!(
        bnb_balance: bnb,
        token_balances: balances,
        balance_checked_at: Time.current
      )
      true
    end

    private

    def wei_to_display(wei, decimals = 18)
      BigDecimal(wei.to_s) / (BigDecimal(10)**decimals)
    end
  end
end
