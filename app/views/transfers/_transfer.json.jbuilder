json.extract! transfer, :id, :from_address_id, :to_address_id, :token_id, :batch_id, :tx_hash, :amount, :status, :error_message, :broadcasted_at, :confirmed_at, :created_at, :updated_at
json.url transfer_url(transfer, format: :json)
