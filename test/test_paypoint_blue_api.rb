require 'minitest_helper'

class TestPayPointBlueAPI < Minitest::Test
  def setup
    @blue = PayPoint::Blue.api_client(endpoint: :test, inst_id: '1234', api_id: 'ABC', api_password: 'secret')
  end

  def test_ping
    stub_api_get('transactions/ping').to_return(fixture("ping"))
    response = @blue.ping
    assert_equal true, response
  end

  def test_make_payment
    payload = payment_payload
    stub_api_post('transactions/1234/payment').with(body: payload).to_return(fixture("make_payment.json"))
    response = @blue.make_payment(**payload)
    assert_equal 'AUTHORISED',  response['processing']['authResponse']['status']
    assert_equal '10044236139', response['transaction']['transactionId']
    assert_equal 'SUCCESS',     response['transaction']['status']
    assert_equal 'PAYMENT',     response['transaction']['type']
    assert_equal 'T283mzh6EUc1yo5JJdwmPzA', response['trace']
  end

  def test_submit_authorisation
    payload = payment_payload
    payload_with_deferred = payload.dup.merge! transaction: payload[:transaction].merge(deferred: true)
    stub_api_post('transactions/1234/payment').with(body: payload_with_deferred).to_return(fixture("submit_authorisation.json"))
    response = @blue.submit_authorisation(**payload)
    assert_equal 'AUTHORISED',  response['processing']['authResponse']['status']
    assert_equal '10044236140', response['transaction']['transactionId']
    assert_equal 'SUCCESS',     response['transaction']['status']
    assert_equal 'PREAUTH',     response['transaction']['type']
    assert_equal 'TCrwo0E9yjBrgCynkFdNlgw', response['trace']
  end

  private

  def payment_payload
    {
      transaction: {
        merchantRef: "xyz-1234",
        amount: "4.89",
        currency: "GBP",
        commerceType: "ECOM"
      },
      customer: {
        merchantRef: "42",
        displayName: "John Doe"
      },
      paymentMethod: {
        card: {
          pan: "9900000000005159",
          expiryDate: "1215",
          nickname: "primary card"
        }
      },
      locale: "en"
    }
  end
end
