require "csv"

class KeystoreBackupService
  Result = Struct.new(:ok, :csv, :count, :message, keyword_init: true) do
    def ok? = !!ok
  end

  class << self
    def call(addresses:, password:)
      scope = addresses.where.not(keystore: nil)

      if scope.empty?
        return Result.new(ok: false, message: "没有可备份的地址（全部无加密私钥）")
      end

      rows   = []
      failed = []

      scope.find_each do |addr|
        begin
          key = WalletService.decrypt(addr.keystore, password)
          rows << [addr.address, key.private_hex, addr.label.to_s]
        rescue WalletService::InvalidPassword
          failed << addr.address
        end
      end

      if rows.empty?
        return Result.new(ok: false, message: "执行密码错误，无法解密任何地址")
      end

      if failed.any?
        return Result.new(
          ok: false,
          message: "#{failed.size} 个地址无法用此密码解密（首个：#{failed.first}），" \
                   "请确认这些地址使用统一的执行密码"
        )
      end

      csv = CSV.generate(headers: true) do |c|
        c << ["address", "private_key_hex", "label"]
        rows.each { |r| c << r }
      end

      Result.new(ok: true, csv: csv, count: rows.size, message: "成功备份 #{rows.size} 条")
    end
  end
end
