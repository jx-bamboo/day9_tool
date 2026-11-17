require "test_helper"

class FromAddressesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @from_address = from_addresses(:one)
  end

  test "should get index" do
    get from_addresses_url
    assert_response :success
  end

  test "should get new" do
    get new_from_address_url
    assert_response :success
  end

  test "should create from_address" do
    assert_difference("FromAddress.count") do
      post from_addresses_url, params: { from_address: { address: @from_address.address, balance_checked_at: @from_address.balance_checked_at, bnb_balance: @from_address.bnb_balance, keystore: @from_address.keystore, label: @from_address.label, token_balances: @from_address.token_balances } }
    end

    assert_redirected_to from_address_url(FromAddress.last)
  end

  test "should show from_address" do
    get from_address_url(@from_address)
    assert_response :success
  end

  test "should get edit" do
    get edit_from_address_url(@from_address)
    assert_response :success
  end

  test "should update from_address" do
    patch from_address_url(@from_address), params: { from_address: { address: @from_address.address, balance_checked_at: @from_address.balance_checked_at, bnb_balance: @from_address.bnb_balance, keystore: @from_address.keystore, label: @from_address.label, token_balances: @from_address.token_balances } }
    assert_redirected_to from_address_url(@from_address)
  end

  test "should destroy from_address" do
    assert_difference("FromAddress.count", -1) do
      delete from_address_url(@from_address)
    end

    assert_redirected_to from_addresses_url
  end
end
