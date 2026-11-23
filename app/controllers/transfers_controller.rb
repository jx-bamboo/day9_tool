# class TransfersController < ApplicationController
#   before_action :set_transfer, only: %i[ show edit update destroy ]
#
#   # GET /transfers or /transfers.json
#   def index
#     @transfers = Transfer.all
#   end
#
#   # GET /transfers/1 or /transfers/1.json
#   def show
#   end
#
#   # GET /transfers/new
#   def new
#     @transfer = Transfer.new
#   end
#
#   # GET /transfers/1/edit
#   def edit
#   end
#
#   # POST /transfers or /transfers.json
#   def create
#     @transfer = Transfer.new(transfer_params)
#
#     respond_to do |format|
#       if @transfer.save
#         format.html { redirect_to @transfer, notice: "Transfer was successfully created." }
#         format.json { render :show, status: :created, location: @transfer }
#       else
#         format.html { render :new, status: :unprocessable_content }
#         format.json { render json: @transfer.errors, status: :unprocessable_content }
#       end
#     end
#   end
#
#   # PATCH/PUT /transfers/1 or /transfers/1.json
#   def update
#     respond_to do |format|
#       if @transfer.update(transfer_params)
#         format.html { redirect_to @transfer, notice: "Transfer was successfully updated.", status: :see_other }
#         format.json { render :show, status: :ok, location: @transfer }
#       else
#         format.html { render :edit, status: :unprocessable_content }
#         format.json { render json: @transfer.errors, status: :unprocessable_content }
#       end
#     end
#   end
#
#   # DELETE /transfers/1 or /transfers/1.json
#   def destroy
#     @transfer.destroy!
#
#     respond_to do |format|
#       format.html { redirect_to transfers_path, notice: "Transfer was successfully destroyed.", status: :see_other }
#       format.json { head :no_content }
#     end
#   end
#
#   private
#     # Use callbacks to share common setup or constraints between actions.
#     def set_transfer
#       @transfer = Transfer.find(params.expect(:id))
#     end
#
#     # Only allow a list of trusted parameters through.
#     def transfer_params
#       params.expect(transfer: [ :from_address_id, :to_address_id, :token_id, :batch_id, :tx_hash, :amount, :status, :error_message, :broadcasted_at, :confirmed_at ])
#     end
# end
class TransfersController < ApplicationController
  before_action :authenticate_user!
  include Pagy::Method

  # GET /transfers
  def index
    @pagy, @transfers = pagy(current_user.transfers.recent.includes(:from_address, :to_address, :token), items: 20)
    # @active_batch_id = Transfer.where(status: %i[pending broadcasting]).pick(:batch_id)
  end

  # GET /transfers/new_dispatch
  def new_dispatch
    @from_addresses = current_user.from_addresses.where.not(keystore: nil).order(:address)
    @pagy, @to_addresses = pagy(current_user.to_addresses.order(:address), items: 50)
    @tokens = Token.active
    @default_token = Token.native_for(56)
  end

  def submit_dispatch
    from_address = FromAddress.find(params[:from_address_id])
    token        = Token.find(params[:token_id])
    to_ids       = Array(params[:to_address_ids]).reject(&:blank?).map(&:to_i).uniq
    password     = params[:execution_password].to_s

    if to_ids.empty?
      return redirect_to new_dispatch_transfers_path, alert: "请至少选择一个接收地址"
    end

    unless password.length >= 8
      return redirect_to new_dispatch_transfers_path, alert: "执行密码至少 8 位"
    end

    unless WalletService.valid_password?(from_address, password)
      return redirect_to new_dispatch_transfers_path, alert: "执行密码错误"
    end

    to_addresses = ToAddress.where(id: to_ids).order(:id)
    amounts = compute_amounts(params, to_addresses.count, token)

    if amounts.any? { |a| a <= 0 }
      return redirect_to new_dispatch_transfers_path, alert: "分发金额必须大于 0"
    end

    batch_id = SecureRandom.uuid
    # 密码只在内存缓存中存活 10 分钟，Job 取用后即删
    Rails.cache.write("dispatch_pwd:#{batch_id}", password, expires_in: 10.minutes)

    transfers = to_addresses.each_with_index.map do |to, i|
      Transfer.create!(
        user: current_user,
        from_address: from_address,
        to_address:   to,
        token:        token,
        batch_id:     batch_id,
        amount:       amounts[i],
        status:       :pending
      )
    end

    AuditService.log!(
      action: "dispatch_submitted",
      user: current_user,
      auditable: from_address,
      metadata: { batch_id: batch_id, count: transfers.count, token: token.symbol },
      request: request
    )

    DistributionJob.perform_later(batch_id, current_user.id)

    redirect_to transfers_path,
                notice: "已提交 #{transfers.count} 笔分发（批次 #{batch_id[0, 8]}），后台执行中"
  rescue ActiveRecord::RecordNotFound => e
    redirect_to new_dispatch_transfers_path, alert: "未找到记录：#{e.message}"
  rescue ArgumentError => e
    redirect_to new_dispatch_transfers_path, alert: "参数错误：#{e.message}"
  rescue StandardError => e
    Rails.logger.error("[TransfersController#dispatch] #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    redirect_to new_dispatch_transfers_path, alert: "分发提交失败：#{e.message}"
  end

  # POST /transfers/pause
  def pause
    batch_id = params[:batch_id].to_s
    Rails.cache.write("dispatch_paused:#{batch_id}", true, expires_in: 2.hours)
    AuditService.log!(
      action: "dispatch_paused",
      user: current_user,
      metadata: { batch_id: batch_id },
      request: request
    )
    redirect_to transfers_path, notice: "批次 #{batch_id[0, 8]} 已暂停"
  end

  # POST /transfers/resume
  def resume
    batch_id = params[:batch_id].to_s
    Rails.cache.delete("dispatch_paused:#{batch_id}")
    AuditService.log!(
      action: "dispatch_resumed",
      user: current_user,
      metadata: { batch_id: batch_id },
      request: request
    )
    redirect_to transfers_path, notice: "批次 #{batch_id[0, 8]} 已恢复"
  end

  # GET /transfers/:id
  def show
    @transfer = Transfer.find(params[:id])
  end

  private

  def compute_amounts(params, count, token)
    decimals = token.decimals.to_i
    factor = BigDecimal(10)**decimals

    if params[:amount_mode] == "random"
      min = params[:min_amount].to_s.to_d
      max = params[:max_amount].to_s.to_d
      raise ArgumentError, "随机最小值必须大于 0" if min <= 0
      raise ArgumentError, "随机最小值不能大于最大值" if min > max

      Array.new(count) do
        human = min + (max - min) * rand
        (human * factor).to_i
      end
    else
      fixed = params[:fixed_amount].to_s.to_d
      raise ArgumentError, "固定金额必须大于 0" if fixed <= 0
      Array.new(count) { (fixed * factor).to_i }
    end
  end
end
