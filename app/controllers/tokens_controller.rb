class TokensController < ApplicationController
  before_action :authenticate_user!
  before_action :set_token, only: %i[ show edit update destroy ]

  # GET /tokens or /tokens.json
  def index
    @tokens = Token.all
  end

  # GET /tokens/1 or /tokens/1.json
  def show
  end

  # GET /tokens/new
  def new
    @token = Token.new
  end

  # GET /tokens/1/edit
  def edit
  end

  # POST /tokens or /tokens.json
#   def create
#     @token = Token.new(token_params)
#
#     respond_to do |format|
#       if @token.save
#         format.html { redirect_to @token, notice: "Token was successfully created." }
#         format.json { render :show, status: :created, location: @token }
#       else
#         format.html { render :new, status: :unprocessable_content }
#         format.json { render json: @token.errors, status: :unprocessable_content }
#       end
#     end
#   end
  def create
    p params, '....'
    contract = params[:contract_address].to_s.strip

    unless contract.match?(/\A0x[a-fA-F0-9]{40}\z/)
      return redirect_to tokens_path, alert: "合约地址格式不正确"
    end

    if Token.exists?(chain_id: 56, token_type: :bep20, contract_address: contract)
      return redirect_to tokens_path, alert: "该代币已导入"
    end

    meta = TokenMetadataService.new(contract).fetch

    token = Token.create!(
      contract_address: contract,
      chain_id: 56,
      token_type: :bep20,
      name: meta[:name],
      symbol: meta[:symbol],
      decimals: meta[:decimals]
    )

    AuditService.log!(
      action: "token_imported",
      user: current_user,
      auditable: token,
      metadata: { symbol: meta[:symbol], name: meta[:name], decimals: meta[:decimals] },
      request: request
    )

    redirect_to tokens_path, notice: "导入成功：#{meta[:symbol]}"

  rescue TokenMetadataService::NotErc20 => e
    redirect_to tokens_path, alert: e.message
  rescue ActiveRecord::RecordInvalid => e
    redirect_to tokens_path, alert: "保存失败：#{e.record.errors.full_messages.join('，')}"
  rescue IOError => e
    # eth.rb 在 RPC 连接失败或节点返回错误时抛出 IOError
    redirect_to tokens_path, alert: "RPC 连接或节点返回错误：#{e.message}"
  rescue StandardError => e
    # 最后的兜底，避免因未知异常导致 500
    Rails.logger.error("[TokensController#create] #{e.class}: #{e.message}")
    redirect_to tokens_path, alert: "导入失败：#{e.message}"
  end

  # PATCH/PUT /tokens/1 or /tokens/1.json
  def update
    respond_to do |format|
      if @token.update(token_params)
        format.html { redirect_to @token, notice: "Token was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @token }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @token.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /tokens/1 or /tokens/1.json
  def destroy
    if @token.native?
      return redirect_to tokens_path, alert: "原生币不可删除"
    end
    @token.destroy!
    AuditService.log!(
      action: "token_deleted",
      user: current_user,
      auditable: @token,
      metadata: { symbol: @token.symbol },
      request: request
    )

    respond_to do |format|
      format.html { redirect_to tokens_path, notice: "Token was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_token
      @token = Token.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def token_params
      params.expect(token: [ :name, :symbol, :contract_address, :decimals, :token_type, :chain_id ])
    end

    def read_erc20_meta(contract)
        client = BalanceService.client
        name = String.new(client.eth_call({ to: contract, data: "0x06fdde03" })).force_encoding("UTF-8") rescue "Unknown"
        symbol = String.new(client.eth_call({ to: contract, data: "0x95d89b41" })).force_encoding("UTF-8") rescue "UNKNOWN"
        decimals_hex = client.eth_call({ to: contract, data: "0x313ce567" })
        decimals = decimals_hex.to_i(16)

        # 简化处理：部分合约返回 ABI 编码的 string，实际业务里建议用 Eth::Contract 解析
        [name, symbol, decimals]
      end
end
