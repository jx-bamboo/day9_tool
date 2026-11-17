class BalanceRefreshJob < ApplicationJob
  queue_as :low
  def perform(record_id, klass_name)
    record = klass_name.constantize.find(record_id)
    BalanceService.refresh_address!(record)
  rescue => e
    Rails.logger.warn("[BalanceRefreshJob] #{klass_name}##{record_id}: #{e.message}")
  end
end
