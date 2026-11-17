class FromAddress < ApplicationRecord
  belongs_to :user, optional: true
  has_many :transfers, dependent: :restrict_with_error

  encrypts :keystore

  validates :address, presence: true, uniqueness: true,
            format: { with: /\A0x[a-fA-F0-9]{40}\z/ }
  validates :keystore, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :stale_balance, -> { where("balance_checked_at IS NULL OR balance_checked_at < ?", 5.minutes.ago) }

  def signable? = keystore.present?
  def short_address = "#{address[0, 6]}…#{address[-4..]}"
end
