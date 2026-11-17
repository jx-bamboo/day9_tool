class AuditService
  class << self
    def log!(action:, user: nil, auditable: nil, metadata: {}, request: nil)
      AuditLog.create!(
        user: user,
        action: action,
        auditable: auditable,
        ip_address: request&.remote_ip,
        metadata: sanitize(metadata)
      )
    end

    private

    # 永远不记密码 / 私钥 / keystore
    def sanitize(metadata)
      metadata.reject { |k, _| k.to_s.match?(/password|private|keystore/i) }
    end
  end
end
