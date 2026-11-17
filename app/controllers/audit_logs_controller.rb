class AuditLogsController < ApplicationController
  before_action :authenticate_user!
  include Pagy::Method

  def index
    @pagy, @logs = pagy(
      current_user.audit_logs.recent.includes(:user, :auditable),
      items: 10
    )
  end
end
