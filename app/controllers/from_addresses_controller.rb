class FromAddressesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_from_address, only: %i[ show edit update destroy ]

  # GET /from_addresses or /from_addresses.json
  def index
    # @from_addresses = FromAddress.all
    @from_addresses = current_user.from_addresses.recent
  end

  # GET /from_addresses/1 or /from_addresses/1.json
  def show
  end

  # GET /from_addresses/new
  def new
    @from_address = FromAddress.new
  end

  # GET /from_addresses/1/edit
  def edit
  end

  # POST /from_addresses or /from_addresses.json
#   def create
#     @from_address = FromAddress.new(from_address_params)
#
#     respond_to do |format|
#       if @from_address.save
#         format.html { redirect_to @from_address, notice: "From address was successfully created." }
#         format.json { render :show, status: :created, location: @from_address }
#       else
#         format.html { render :new, status: :unprocessable_content }
#         format.json { render json: @from_address.errors, status: :unprocessable_content }
#       end
#     end
#   end
# 覆盖 scaffold 的 create，支持批量生成
  def create
    count    = params[:count].to_i
    password = params[:encryption_password]

    if params[:encryption_password] != params[:encryption_password_confirmation]
      return redirect_to from_addresses_path, alert: "两次密码不一致"
    end

    if count < 1 || password.to_s.length < 8
      return redirect_to from_addresses_path, alert: "数量 ≥ 1 且密码 ≥ 8 位"
    end

    rows = WalletService.generate_batch(count: count, password: password, user: current_user)
    rows.each do |r|
      FromAddress.create!(r.merge(user: current_user))
    end

    AuditService.log!(
      action: "from_address_created",
      user: current_user,
      request: request,
      auditable: @from_address,
      metadata: { count: count }
    )
    redirect_to from_addresses_path, notice: "成功生成 #{count} 个分发地址"
  rescue => e
    redirect_to from_addresses_path, alert: e.message
  end

  # PATCH/PUT /from_addresses/1 or /from_addresses/1.json
  def update
    respond_to do |format|
      if @from_address.update(from_address_params)
        format.html { redirect_to @from_address, notice: "From address was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @from_address }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @from_address.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /from_addresses/1 or /from_addresses/1.json
  def destroy
    @from_address.destroy!
    AuditService.log!(
      action: "from_address_deleted",
      user: current_user,
      auditable: @from_address,
      metadata: { address: @from_address.address },
      request: request
    )

    respond_to do |format|
      format.html { redirect_to from_addresses_path, notice: "From address was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  # 单条导入
  def import
    # GET 显示导入表单
  end

  def do_import
    private_key = params[:private_key].to_s.strip
    password    = params[:encryption_password]

    if private_key.blank? || password.to_s.length < 8
      return redirect_to from_addresses_path, alert: "私钥与密码不能为空，密码 ≥ 8 位"
    end

    data = WalletService.import_one(private_key_hex: private_key, password: password)
    FromAddress.create!(data.merge(user: current_user))

    AuditService.log!(
      action: "from_address_imported",
      user: current_user,
      request: request,
      auditable: @from_address,
      metadata: { address: data[:address] }
    )
    redirect_to from_addresses_path, notice: "导入成功"
  rescue => e
    redirect_to from_addresses_path, alert: "导入失败：#{e.message}"
  end

  # 批量刷新余额（异步）
  def refresh_balances
    FromAddress.find_each { |r| BalanceRefreshJob.perform_later(r.id, "FromAddress") }
    redirect_to from_addresses_path, notice: "已提交刷新，稍后自动更新"
  end

  def qr
    render json: { address: @record.address }
  end

  def backup_keystore
    password = params[:execution_password].to_s

    if password.length < 8
      return redirect_to from_addresses_path, alert: "执行密码至少 8 位"
    end

    result = KeystoreBackupService.call(
      addresses: current_user.from_addresses,
      password: password
    )

    unless result.ok?
      return redirect_to from_addresses_path, alert: result.message
    end

    AuditService.log!(
      action: "keystore_backup",
      user: current_user,
      metadata: { scope: "from_addresses", count: result.count },
      request: request
    )

    send_data result.csv,
              filename: "from_addresses_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv",
              type: "text/csv",
              disposition: "attachment"
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_from_address
      @from_address = FromAddress.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def from_address_params
      params.expect(from_address: [ :address, :keystore, :label, :bnb_balance, :token_balances, :balance_checked_at ])
    end
end
