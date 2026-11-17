class ToAddress < ApplicationRecord
  belongs_to :user, optional: true
  has_many :transfers, dependent: :restrict_with_error

  encrypts :keystore

  validates :address, presence: true, uniqueness: true,
            format: { with: /\A0x[a-fA-F0-9]{40}\z/ }

  scope :recent, -> { order(created_at: :desc) }

  def signable? = keystore.present?
  def short_address = "#{address[0, 6]}…#{address[-4..]}"
end
