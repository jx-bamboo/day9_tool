class CreateToAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :to_addresses do |t|
      t.string :address
      t.text :keystore
      t.string :label, :status
      t.decimal :bnb_balance
      t.json :token_balances
      t.datetime :balance_checked_at, :last_used_at, :deleted_at
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    add_index :to_addresses, :address, unique: true
    add_index :to_addresses, :keystore, unique: true
  end
end
