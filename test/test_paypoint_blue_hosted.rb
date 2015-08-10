require "minitest_helper"

class TestPayPointBlueHosted < Minitest::Test
  def setup
    @blue = PayPoint::Blue.hosted_client(
      endpoint: :test, inst_id: "1234", api_id: "ABC", api_password: "secret",
      defaults: {
        currency:          "GBP",
        skin:              "9001",
        return_url:        "http://example.com/callback/return",
        pre_auth_callback: "http://example.com/callback/preauth",
      }
    )
  end

  def test_delegates_api_methods_to_regular_client
    PayPoint::Blue::API.instance_methods(false).each do |api_method|
      assert_respond_to @blue, api_method
    end
  end

  def test_ping
    stub_hosted_get("sessions/ping").to_return(fixture("ping"))
    response = @blue.ping
    assert_equal true, response
  end

  def test_make_payment
    stub_hosted_post("sessions/1234/payments")
      .with(body: request_payload)
      .to_return(fixture("make_payment_hosted.json"))

    response = @blue.make_payment(**payment_payload)
    assert_equal "39b3e3ec-92f4-48c4-aac8-c6c8bc9f6627", response.session_id
    assert_equal "https://hosted.mite.paypoint.net/hosted/4d9d53b5-06fc-41bb-91c6-a30e81175ed0" \
                   "/begin/39b3e3ec-92f4-48c4-aac8-c6c8bc9f6627", response.redirect_url
    assert_equal "SUCCESS", response.status
  end

  def test_payload_shortcuts
    stub_hosted_post("sessions/1234/payments")
      .with(body: request_payload)
      .to_return(fixture("make_payment_hosted.json"))

    response = @blue.make_payment(
      merchant_ref:  "abcd-1234",
      amount:        "4.89",
      customer_ref:  "42",
      customer_name: "John Doe",
      locale:        "en",
    )
    assert_equal "39b3e3ec-92f4-48c4-aac8-c6c8bc9f6627", response.session_id
    assert_equal "https://hosted.mite.paypoint.net/hosted/4d9d53b5-06fc-41bb-91c6-a30e81175ed0" \
                   "/begin/39b3e3ec-92f4-48c4-aac8-c6c8bc9f6627", response.redirect_url
    assert_equal "SUCCESS", response.status
  end

  def test_submit_authorisation
    payload_with_deferred = request_payload
    payload_with_deferred[:transaction][:deferred] = true
    stub_hosted_post("sessions/1234/payments")
      .with(body: payload_with_deferred)
      .to_return(fixture("submit_authorisation_hosted.json"))

    response = @blue.submit_authorisation(**payment_payload)
    assert_equal "4e88554a-fb20-4527-a1c1-1a19ebf23c94", response.session_id
    assert_equal "https://hosted.mite.paypoint.net/hosted/2455020b-928f-4515-88bb-b18f4283adfe" \
                   "/begin/4e88554a-fb20-4527-a1c1-1a19ebf23c94", response.redirect_url
    assert_equal "SUCCESS", response.status
  end

  def test_submit_payout
    stub_hosted_post("sessions/1234/payouts")
      .with(body: request_payload)
      .to_return(fixture("submit_payout_hosted.json"))

    response = @blue.submit_payout(**payment_payload)
    assert_equal "9427d641-54b5-496c-a989-22c284144eb6", response.session_id
    assert_equal "https://hosted.mite.paypoint.net/hosted/1acebe67-c90d-47b0-b721-45dc015b2479" \
                   "/begin/9427d641-54b5-496c-a989-22c284144eb6", response.redirect_url
    assert_equal "SUCCESS", response.status
  end

  def test_transaction_not_found
    merchant_ref = "xyz-42"
    stub_api_get("transactions/1234/byRef?merchantRef=#{merchant_ref}")
      .to_return(fixture("transaction_not_found.json"))

    error = assert_raises(PayPoint::Blue::Error::NotFound) do
      @blue.transactions_by_ref(merchant_ref)
    end
    # NOTE: The transaction not found error response doesn't include
    # an `outcome` field, therefore the message will be generic
    assert_equal "the server responded with status 404", error.message
    assert_nil error.code
  end

  private

  def payment_payload
    {
      transaction: {
        merchant_reference: "abcd-1234",
        money:              { amount: { fixed: "4.89" } },
      },
      customer:    {
        identity: { merchant_customer_id: "42" },
        details:  { name: "John Doe" },
      },
      locale:      "en",
    }
  end

  def request_payload
    with_defaults = payment_payload.dup.tap do |hash|
      hash[:transaction] = hash[:transaction].dup.tap do |txn_hash|
        txn_hash[:money] = txn_hash[:money].merge currency: "GBP"
      end
      hash[:session] = {
        return_url:        { url: "http://example.com/callback/return" },
        pre_auth_callback: { url: "http://example.com/callback/preauth", format: "REST_JSON" },
        skin:              "9001",
      }
    end
    camelcase_and_symbolize_keys(with_defaults)
  end
end
