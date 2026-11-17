class Token < ApplicationRecord
  enum :token_type, { native: 0, bep20: 1 }, default: :bep20

  validates :contract_address, presence: true
  validates :name, :symbol, presence: true
  validates :contract_address, uniqueness: { scope: [:chain_id, :token_type] }
  validates :decimals, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { order(:token_type, :symbol) }

  def decimals_factor = 10**decimals.to_i

  # BNB 使用内置记录
  def self.native_for(chain_id)
    find_or_create_by!(chain_id: chain_id, token_type: :native, contract_address: "native") do |t|
      t.symbol = "BNB"
      t.name   = "BNB"
      t.decimals = 18
      t.user_id = 1
    end
  end
end
