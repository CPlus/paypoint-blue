require "minitest_helper"

class TestPayPointBlueHosted < Minitest::Test
  def setup
    @blue = PayPoint::Blue.hosted_client(
      endpoint: :test, inst_id: "1234", api_id: "ABC", api_password: "secret",
      defaults: {
        currency:          "GBP",
        skin:              "9001",
        return_url:        "http://example.com/callback/return",
        cancel_url:        "http://example.com/callback/cancel",
        pre_auth_callback: "http://example.com/callback/preauth",
      }
    )
  end

  def test_delegates_api_methods_to_regular_client
    methods = PayPoint::Blue::API.instance_methods(false) - [:remove_card]
    methods.each do |api_method|
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

  def test_manage_cards
    stub_hosted_post("sessions/1234/cards")
      .with(body: cards_request_payload)
      .to_return(fixture("manage_cards_hosted.json"))

    response = @blue.manage_cards(
      customer_ref: "bob",
      return_url:   "http://example.com/callback",
    )

    assert_equal "aa083d17-e3ef-4b82-ab95-3a4e51decba8", response.session_id
    assert_equal "https://hosted.mite.paypoint.net/hosted/aa083d17-e3ef-4b82-ab95-3a4e51decba8" \
                   "/begin/aa083d17-e3ef-4b82-ab95-3a4e51decba8", response.redirect_url
    assert_equal "SUCCESS", response.status
  end

  def test_skins
    stub_hosted_get("skins/1234/list").to_return(fixture("skins.json"))

    response = @blue.skins

    assert_equal 1, response.skins[0].id
    assert_equal "Pay360 Blue", response.skins[0].name
    assert_equal "Pay360", response.skins[0].organisation
    assert_equal "SUCCESS", response.status
  end

  def test_download_skin
    stub_hosted_get("skins/1234").to_return(fixture("download_skin"))

    response = @blue.download_skin(1234)

    assert_equal 150, response
  end

  def test_download_skin_with_wrong_id
    stub_hosted_get("skins/1234")
      .to_return(fixture("download_skin_with_wrong_id"))

    error = assert_raises(PayPoint::Blue::Error::Client) do
      @blue.download_skin(1234)
    end

    assert_equal "the server responded with status 500", error.message
    assert_nil error.code
  end

  def test_upload_skin
    stub_hosted_post("skins/1234/create?name=Test%20skin")
      .with(body: File.read(fixture("test_skin.zip")))
      .to_return(fixture("upload_skin.json"))

    response = @blue.upload_skin(fixture("test_skin.zip"), name: "Test skin")

    assert_equal 2, response.skin.id
    assert_equal "Test skin", response.skin.name
    assert_equal "Collect Plus", response.skin.organisation
    assert_equal "SUCCESS", response.status
  end

  def test_replace_skin
    stub_hosted_put("skins/1234?name=Test%20skin2")
      .with(body: File.read(fixture("test_skin.zip")))
      .to_return(fixture("replace_skin.json"))

    response = @blue.replace_skin 1234,
      file: fixture("test_skin.zip"), name: "Test skin2"

    assert_equal 1234, response.skin.id
    assert_equal "Test skin2", response.skin.name
    assert_equal "Collect Plus", response.skin.organisation
    assert_equal "SUCCESS", response.status
  end

  def test_replace_skin_without_name
    stub_hosted_put("skins/1234")
      .with(body: File.read(fixture("test_skin.zip")))
      .to_return(fixture("replace_skin.json"))

    response = @blue.replace_skin(1234, file: fixture("test_skin.zip"))

    assert_equal 1234, response.skin.id
    assert_equal "Test skin2", response.skin.name
    assert_equal "Collect Plus", response.skin.organisation
    assert_equal "SUCCESS", response.status
  end

  def test_replace_skin_without_file
    stub_hosted_put("skins/1234?name=Test%20skin2")
      .to_return(fixture("replace_skin.json"))

    response = @blue.replace_skin(1234, name: "Test skin2")

    assert_equal 1234, response.skin.id
    assert_equal "Test skin2", response.skin.name
    assert_equal "Collect Plus", response.skin.organisation
    assert_equal "SUCCESS", response.status
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
        cancel_url:        { url: "http://example.com/callback/cancel" },
        pre_auth_callback: { url: "http://example.com/callback/preauth", format: "REST_JSON" },
        skin:              "9001",
      }
    end
    camelcase_and_symbolize_keys(with_defaults)
  end

  def cards_request_payload
    camelcase_and_symbolize_keys(
      customer: { identity: { merchant_customer_id: "bob" } },
      session:  {
        return_url: { url: "http://example.com/callback" },
        skin:       "9001",
      },
    )
  end
end
