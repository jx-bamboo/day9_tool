class CreateTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :tokens do |t|
      t.string :name, :symbol
      t.string :contract_address, null: false
      t.integer :status # 0 disabled 1 active
      t.integer :decimals, null: false, default: 18
      t.integer :token_type, null: false, default: 1   # 0=native, 1=bep20
      t.integer :chain_id, null: false, default: 56
      t.text :abi
      t.datetime :deleted_at
      t.references :user, null: true, foreign_key: true

      t.timestamps
    end
    add_index :tokens, :contract_address, unique: true
    add_index :tokens, :deleted_at
  end
end
