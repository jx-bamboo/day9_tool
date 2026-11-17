class CreateTransfers < ActiveRecord::Migration[8.1]
  def change
    create_table :transfers do |t|
      t.references :from_address, null: false, foreign_key: true
      t.references :to_address, null: false, foreign_key: true
      t.references :token, null: false, foreign_key: true
      t.string :batch_id, index: true
      t.string :tx_hash, index: true
      t.decimal :amount
      t.integer :status, index: true #pending / broadcasting / confirmed / failed
      t.text :error_message
      t.datetime :broadcasted_at
      t.datetime :confirmed_at
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
