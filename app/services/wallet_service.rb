class WalletService
  class InvalidPassword < StandardError; end

  class << self
    # 批量生成 N 个地址，每个 keystore 用同一密码加密
    def generate_batch(count:, password:, user:)
      raise ArgumentError, "密码至少 8 位" if password.to_s.length < 8
      raise ArgumentError, "单次最多 500 个" if count.to_i > 500

      Array.new(count.to_i) do
        key = Eth::Key.new
        keystore_json = Eth::Key::Encrypter.perform(key, password)
        { address: key.address.to_s, keystore: keystore_json }
      end
    end

    # 单条导入
    def import_one(private_key_hex:, password:)
      raise ArgumentError, "密码至少 8 位" if password.to_s.length < 8
      key = Eth::Key.new(priv: private_key_hex)
      {
        address: key.address.to_s,
        keystore: Eth::Key::Encrypter.perform(key, password)
      }
    end

    # 解密：拿到 Eth::Key
    def decrypt(keystore, password)
      Eth::Key::Decrypter.perform(keystore, password)
    rescue StandardError => e
      Rails.logger.warn("[WalletService.decrypt] #{e.class}: #{e.message}")
      raise InvalidPassword, "执行密码错误"
    end

    def valid_password?(record, password)
      return false unless record.keystore.present?
      decrypt(record.keystore, password)
      true
    rescue InvalidPassword
      false
    end
  end
end
