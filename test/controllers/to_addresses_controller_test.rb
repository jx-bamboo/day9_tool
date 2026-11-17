require "test_helper"

class ToAddressesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @to_address = to_addresses(:one)
  end

  test "should get index" do
    get to_addresses_url
    assert_response :success
  end

  test "should get new" do
    get new_to_address_url
    assert_response :success
  end

  test "should create to_address" do
    assert_difference("ToAddress.count") do
      post to_addresses_url, params: { to_address: { address: @to_address.address, balance_checked_at: @to_address.balance_checked_at, bnb_balance: @to_address.bnb_balance, keystore: @to_address.keystore, label: @to_address.label, token_balances: @to_address.token_balances } }
    end

    assert_redirected_to to_address_url(ToAddress.last)
  end

  test "should show to_address" do
    get to_address_url(@to_address)
    assert_response :success
  end

  test "should get edit" do
    get edit_to_address_url(@to_address)
    assert_response :success
  end

  test "should update to_address" do
    patch to_address_url(@to_address), params: { to_address: { address: @to_address.address, balance_checked_at: @to_address.balance_checked_at, bnb_balance: @to_address.bnb_balance, keystore: @to_address.keystore, label: @to_address.label, token_balances: @to_address.token_balances } }
    assert_redirected_to to_address_url(@to_address)
  end

  test "should destroy to_address" do
    assert_difference("ToAddress.count", -1) do
      delete to_address_url(@to_address)
    end

    assert_redirected_to to_addresses_url
  end
end
