class HomeController < ApplicationController
  before_action :authenticate_user!, except: [:welcome]
  include Pagy::Method

  def welcome
    return redirect_to home_index_path if user_signed_in?
    render layout: false
  end

  def index
    @from_addresses = current_user.from_addresses.recent.limit(50)
    @pagy, @to_addresses = pagy(current_user.to_addresses.recent, items: 20)
    # @tokens         = Token.active
    # @active_batch_id = Transfer.where(status: [:pending, :broadcasting]).pick(:batch_id)
    # @recent_transfers = Transfer.recent.includes(:from_address, :to_address, :token).limit(50)
  end
end
