class HomeController < ApplicationController
  before_action :authenticate_user!, except: [:welcome]
  include Pagy::Method

  def welcome
    return redirect_to home_index_path if user_signed_in?
    render layout: false
  end

  def index
    @from_pagy, @from_addresses = pagy(
      current_user.from_addresses,
      items: 20,
      root_key: "from_page"
    )
    @to_pagy, @to_addresses = pagy(
      current_user.to_addresses,
      items: 50,
      root_key: "to_page"
    )
    # @tokens         = Token.active
    # @active_batch_id = Transfer.where(status: [:pending, :broadcasting]).pick(:batch_id)
    # @recent_transfers = Transfer.recent.includes(:from_address, :to_address, :token).limit(50)
  end
end
