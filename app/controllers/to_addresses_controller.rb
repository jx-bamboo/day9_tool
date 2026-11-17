class ToAddressesController < ApplicationController
  before_action :authenticate_user!
  include Pagy::Method
  before_action :set_to_address, only: %i[ show edit update destroy ]

  # GET /to_addresses or /to_addresses.json
  def index
    @pagy, @to_addresses = pagy(current_user.to_addresses.all, items: 20)
  end

  # GET /to_addresses/1 or /to_addresses/1.json
  def show
  end

  # GET /to_addresses/new
  def new
    @to_address = ToAddress.new
  end

  # GET /to_addresses/1/edit
  def edit
  end

  # POST /to_addresses or /to_addresses.json
#   def create
#     @to_address = ToAddress.new(to_address_params)
#
#     respond_to do |format|
#       if @to_address.save
#         format.html { redirect_to @to_address, notice: "To address was successfully created." }
#         format.json { render :show, status: :created, location: @to_address }
#       else
#         format.html { render :new, status: :unprocessable_content }
#         format.json { render json: @to_address.errors, status: :unprocessable_content }
#       end
#     end
#   end
  def create
    count    = params[:count].to_i
    password = params[:encryption_password]

    if params[:encryption_password] != params[:encryption_password_confirmation]
      return redirect_to to_addresses_path, alert: "两次密码不一致"
    end

    if count < 1 || password.to_s.length < 8
      return redirect_to to_addresses_path, alert: "数量 ≥ 1 且密码 ≥ 8 位"
    end

    rows = WalletService.generate_batch(count: count, password: password, user: current_user)
    rows.each do |r|
      ToAddress.create!(r.merge(user: current_user))
    end

    AuditService.log!(
      action: "to_addresses_generated",
      user: current_user,
      request: request,
      auditable: @to_address,
      metadata: { count: count }
    )
    redirect_to to_addresses_path, notice: "成功生成 #{count} 个接收地址"
  rescue => e
    redirect_to to_addresses_path, alert: e.message
  end

  # PATCH/PUT /to_addresses/1 or /to_addresses/1.json
  def update
    respond_to do |format|
      if @to_address.update(to_address_params)
        format.html { redirect_to @to_address, notice: "To address was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @to_address }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @to_address.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /to_addresses/1 or /to_addresses/1.json
  def destroy
    @to_address.destroy!
    AuditService.log!(
      action: "to_address_deleted",
      user: current_user,
      auditable: @to_address,
      metadata: { address: @to_address.address },
      request: request
    )

    respond_to do |format|
      format.html { redirect_to to_addresses_path, notice: "To address was successfully destroyed.", status: :see_other }
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
      return redirect_to to_addresses_path, alert: "私钥与密码不能为空，密码 ≥ 8 位"
    end

    data = WalletService.import_one(private_key_hex: private_key, password: password)
    ToAddress.create!(data.merge(user: current_user))

    AuditService.log!(
      action: "to_address_imported",
      user: current_user,
      request: request,
      auditable: @to_address,
      metadata: { address: data[:address] }
    )
    redirect_to to_addresses_path, notice: "导入成功"
  rescue => e
    redirect_to to_addresses_path, alert: "导入失败：#{e.message}"
  end

  # 批量刷新余额（异步）
  def refresh_balances
    ToAddress.find_each { |r| BalanceRefreshJob.perform_later(r.id, "ToAddress") }
    redirect_to to_addresses_path, notice: "已提交刷新，稍后自动更新"
  end

  def qr
    render json: { address: @record.address }
  end

  def backup_keystore
    password = params[:execution_password].to_s

    if password.length < 8
      return redirect_to to_addresses_path, alert: "执行密码至少 8 位"
    end

    result = KeystoreBackupService.call(
      addresses: current_user.to_addresses,
      password: password
    )

    unless result.ok?
      return redirect_to to_addresses_path, alert: result.message
    end

    AuditService.log!(
      action: "keystore_backup",
      user: current_user,
      metadata: { scope: "to_addresses", count: result.count },
      request: request
    )

    send_data result.csv,
              filename: "to_addresses_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv",
              type: "text/csv",
              disposition: "attachment"
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_to_address
      @to_address = ToAddress.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def to_address_params
      params.expect(to_address: [ :address, :keystore, :label, :bnb_balance, :token_balances, :balance_checked_at ])
    end
end
