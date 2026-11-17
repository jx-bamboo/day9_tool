json.extract! token, :id, :name, :symbol, :contract_address, :decimals, :token_type, :chain_id, :created_at, :updated_at
json.url token_url(token, format: :json)
