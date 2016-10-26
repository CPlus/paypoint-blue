require "minitest_helper"

class TestFaradayRunscope < Minitest::Test
  def setup
    @blue = PayPoint::Blue.api_client(
      endpoint: :test, inst_id: "123",
      api_id: "ABC", api_password: "secret",
      runscope: "bucket"
    )
  end

  def test_runscope_integration
    stub_request(:get, endpoint("/transactions/ping"))
      .with(
        headers:    { "Runscope-Request-Port" => "2443" },
        basic_auth: %w(ABC secret),
      )
      .to_return(fixture("ping_runscope"))
    response = @blue.ping
    assert_equal true, response
  end

  def test_runscope_integration_with_payload
    transformed_url = "http://with--dash-example-com-bucket.runscope.net/callback/preauth"
    stub_request(:post, endpoint("/transactions/123/payment"))
      .with(
        headers:    { "Runscope-Request-Port" => "2443" },
        body:       camelcase_and_symbolize_keys(payment_payload(callback_url: transformed_url)),
        basic_auth: %w(ABC secret),
      )
      .to_return(fixture("make_payment_runscope.json"))
    response = @blue.make_payment(**payment_payload)
    assert_equal "AUTHORISED",  response.processing.auth_response.status
    assert_equal "10044237041", response.transaction.transaction_id
    assert_equal "SUCCESS",     response.transaction.status
    assert_equal "PAYMENT",     response.transaction.type
    assert_equal "TiHrFVn79yBWEHY1MDIOcNQ", response.trace
  end

  private

  def endpoint(path)
    "https://api-mite-pay360-com-bucket.runscope.net/acceptor/rest#{path}"
  end

  def payment_payload(callback_url: "http://with-dash.example.com/callback/preauth")
    {
      transaction:    {
        merchant_ref:  "xyz-1234",
        amount:        "4.89",
        currency:      "GBP",
        commerce_type: "ECOM",
      },
      customer:       {
        merchant_ref: "42",
        display_name: "John Doe",
      },
      payment_method: {
        card: {
          pan:         "9900000000005159",
          expiry_date: "1215",
          nickname:    "primary card",
        },
      },
      callbacks:      {
        pre_auth_callback: {
          format: "REST_JSON",
          url:    callback_url,
        },
      },
    }
  end
end
