require 'minitest_helper'

class TestFaradayRunscope < Minitest::Test
  def setup
    @blue = PayPoint::Blue.api_client(endpoint: :test, inst_id: '123', api_id: 'ABC', api_password: 'secret', runscope: 'bucket')
  end

  def test_runscope_integration
    stub_request(:get, "https://ABC:secret@api-mite-paypoint-net-bucket.runscope.net/acceptor/rest/transactions/ping").
      with(headers: { 'Runscope-Request-Port' => '2443' }).
      to_return(fixture("ping_runscope"))
    response = @blue.ping
    assert_equal true, response
  end

  def test_runscope_integration_with_payload
    stub_request(:post, "https://ABC:secret@api-mite-paypoint-net-bucket.runscope.net/acceptor/rest/transactions/123/payment").
      with(
        headers: { 'Runscope-Request-Port' => '2443' },
        body: payment_payload(callback_url: "http://example-com-bucket.runscope.net/callback/preauth")
      ).
      to_return(fixture("make_payment_runscope.json"))
    response = @blue.make_payment(**payment_payload)
    assert_equal 'AUTHORISED',  response['processing']['authResponse']['status']
    assert_equal '10044237041', response['transaction']['transactionId']
    assert_equal 'SUCCESS',     response['transaction']['status']
    assert_equal 'PAYMENT',     response['transaction']['type']
    assert_equal 'TiHrFVn79yBWEHY1MDIOcNQ', response['trace']
  end

  private

  def payment_payload(callback_url: "http://example.com/callback/preauth")
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
      callbacks: {
        preAuthCallback: {
          format: "REST_JSON",
          url: callback_url
        }
      }
    }
  end
end
