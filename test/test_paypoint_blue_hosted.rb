require 'minitest_helper'

class TestPayPointBlueHosted < Minitest::Test
  def setup
    @blue = PayPoint::Blue.hosted_client(endpoint: :test, inst_id: '1234', api_id: 'ABC', api_password: 'secret')
  end

  def test_delegates_api_methods_to_regular_client
    PayPoint::Blue::API.instance_methods(false).each do |api_method|
      assert_respond_to @blue, api_method
    end
  end

  def test_ping
    stub_hosted_get('sessions/ping').to_return(fixture("ping"))
    response = @blue.ping
    assert_equal true, response
  end

  def test_make_payment
    payload = payment_payload
    stub_hosted_post('sessions/1234/payments').with(body: payload).to_return(fixture("make_payment_hosted.json"))
    response = @blue.make_payment(**payload)
    expected = {
      "sessionId" => "39b3e3ec-92f4-48c4-aac8-c6c8bc9f6627",
      "redirectUrl" => "https://hosted.mite.paypoint.net/hosted/4d9d53b5-06fc-41bb-91c6-a30e81175ed0/begin/39b3e3ec-92f4-48c4-aac8-c6c8bc9f6627",
      "status" => "SUCCESS"
    }
    assert_equal expected, response
  end

  def test_submit_authorisation
    payload = payment_payload
    payload_with_deferred = payload.dup.merge! transaction: payload[:transaction].merge(deferred: true)
    stub_hosted_post('sessions/1234/payments').with(body: payload_with_deferred).to_return(fixture("submit_authorisation_hosted.json"))
    response = @blue.submit_authorisation(**payload)
    expected = {
      "sessionId" => "4e88554a-fb20-4527-a1c1-1a19ebf23c94",
      "redirectUrl" => "https://hosted.mite.paypoint.net/hosted/2455020b-928f-4515-88bb-b18f4283adfe/begin/4e88554a-fb20-4527-a1c1-1a19ebf23c94",
      "status" => "SUCCESS"
    }
    assert_equal expected, response
  end

  private

  def payment_payload
    {
      transaction: {
        merchantReference: "abcd-1234",
        money: { amount: { fixed: "4.89" }, currency: "GBP" }
      },
      customer: {
        identity: { merchantCustomerId: "42" },
        details: { name: "John Doe" }
      },
      session: {
        returnUrl: { url: "http://example.com/callback/abcd-1234" },
        skin: "9001"
      },
      locale: "en"
    }
  end
end
