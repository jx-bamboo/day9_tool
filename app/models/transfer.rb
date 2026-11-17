class Transfer < ApplicationRecord
  belongs_to :user
  belongs_to :from_address
  belongs_to :to_address
  belongs_to :token

  enum :status, {
    pending:      0,
    broadcasting: 1,
    confirmed:    2,
    failed:       3
  }, default: :pending

  validates :amount, numericality: { greater_than: 0 }
  validates :batch_id, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :for_batch, ->(bid) { where(batch_id: bid) }

  after_update_commit :broadcast_row, if: :saved_change_to_status?

  def self.batch_summary(batch_id)
    rows = for_batch(batch_id)
    {
      total:        rows.count,
      pending:      rows.pending.count,
      broadcasting: rows.broadcasting.count,
      confirmed:    rows.confirmed.count,
      failed:       rows.failed.count
    }
  end

  private

  def broadcast_row
    Turbo::StreamsChannel.broadcast_replace_to(
      "batch_#{batch_id}",
      target: "transfer_row_#{id}",
      partial: "transfers/row",
      locals: { transfer: self }
    )

    summary = self.class.batch_summary(batch_id)
    return unless summary[:pending].zero? && summary[:broadcasting].zero?

    Turbo::StreamsChannel.broadcast_prepend_to(
      "toasts",
      target: "toast_container",
      partial: "shared/toast",
      locals: {
        kind: summary[:failed].zero? ? "green" : "yellow",
        message: "批次 #{batch_id[0, 8]} 完成：成功 #{summary[:confirmed]} 笔，失败 #{summary[:failed]} 笔"
      }
    )
  end
end
