# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_11_162439) do
  create_table "audit_logs", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "action"
    t.string "auditable_type"
    t.integer "auditable_id"
    t.string "ip_address"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["auditable_type", "auditable_id"], name: "index_audit_logs_on_auditable"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "from_addresses", force: :cascade do |t|
    t.string "address"
    t.text "keystore"
    t.string "label"
    t.string "status"
    t.decimal "bnb_balance"
    t.json "token_balances"
    t.datetime "balance_checked_at"
    t.datetime "last_used_at"
    t.datetime "deleted_at"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address"], name: "index_from_addresses_on_address", unique: true
    t.index ["keystore"], name: "index_from_addresses_on_keystore", unique: true
    t.index ["user_id"], name: "index_from_addresses_on_user_id"
  end

  create_table "to_addresses", force: :cascade do |t|
    t.string "address"
    t.text "keystore"
    t.string "label"
    t.string "status"
    t.decimal "bnb_balance"
    t.json "token_balances"
    t.datetime "balance_checked_at"
    t.datetime "last_used_at"
    t.datetime "deleted_at"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address"], name: "index_to_addresses_on_address", unique: true
    t.index ["keystore"], name: "index_to_addresses_on_keystore", unique: true
    t.index ["user_id"], name: "index_to_addresses_on_user_id"
  end

  create_table "tokens", force: :cascade do |t|
    t.string "name"
    t.string "symbol"
    t.string "contract_address", null: false
    t.integer "status"
    t.integer "decimals", default: 18, null: false
    t.integer "token_type", default: 1, null: false
    t.integer "chain_id", default: 56, null: false
    t.text "abi"
    t.datetime "deleted_at"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contract_address"], name: "index_tokens_on_contract_address", unique: true
    t.index ["deleted_at"], name: "index_tokens_on_deleted_at"
    t.index ["user_id"], name: "index_tokens_on_user_id"
  end

  create_table "transfers", force: :cascade do |t|
    t.integer "from_address_id", null: false
    t.integer "to_address_id", null: false
    t.integer "token_id", null: false
    t.string "batch_id"
    t.string "tx_hash"
    t.decimal "amount"
    t.integer "status"
    t.text "error_message"
    t.datetime "broadcasted_at"
    t.datetime "confirmed_at"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["batch_id"], name: "index_transfers_on_batch_id"
    t.index ["from_address_id"], name: "index_transfers_on_from_address_id"
    t.index ["status"], name: "index_transfers_on_status"
    t.index ["to_address_id"], name: "index_transfers_on_to_address_id"
    t.index ["token_id"], name: "index_transfers_on_token_id"
    t.index ["tx_hash"], name: "index_transfers_on_tx_hash"
    t.index ["user_id"], name: "index_transfers_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "audit_logs", "users"
  add_foreign_key "from_addresses", "users"
  add_foreign_key "to_addresses", "users"
  add_foreign_key "tokens", "users"
  add_foreign_key "transfers", "from_addresses"
  add_foreign_key "transfers", "to_addresses"
  add_foreign_key "transfers", "tokens"
  add_foreign_key "transfers", "users"
end
