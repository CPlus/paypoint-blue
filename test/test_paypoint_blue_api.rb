require 'minitest_helper'

class TestPayPointBlueAPI < Minitest::Test
  def setup
    @blue = PayPoint::Blue.api_client(
      endpoint: :test, inst_id: '1234', api_id: 'ABC', api_password: 'secret',
      defaults: {
        currency: 'GBP',
        commerce_type: 'ECOM',
        pre_auth_callback: 'http://example.com/callback'
      }
    )
  end

  def test_ping
    stub_api_get('transactions/ping').to_return(fixture("ping"))
    response = @blue.ping
    assert_equal true, response
  end

  def test_make_payment
    stub_api_post('transactions/1234/payment').
      with(body: request_payload).
      to_return(fixture("make_payment.json"))

    response = @blue.make_payment(**payment_payload)
    assert_equal 'AUTHORISED',  response.processing.auth_response.status
    assert_equal '10044236139', response.transaction.transaction_id
    assert_equal 'SUCCESS',     response.transaction.status
    assert_equal 'PAYMENT',     response.transaction.type
    assert_equal 'T283mzh6EUc1yo5JJdwmPzA', response.trace
  end

  def test_payload_shortcuts
    stub_api_post('transactions/1234/payment').
      with(body: request_payload).
      to_return(fixture("make_payment.json"))

    response = @blue.make_payment(
      merchant_ref: 'xyz-1234',
      amount: '4.89',
      customer_ref: '42',
      customer_name: 'John Doe',
      payment_method: {
        card: {
          pan: "9900000000005159",
          expiry_date: "1215",
          nickname: "primary card"
        }
      },
      locale: 'en'
    )
    assert_equal 'AUTHORISED',  response.processing.auth_response.status
    assert_equal '10044236139', response.transaction.transaction_id
    assert_equal 'SUCCESS',     response.transaction.status
    assert_equal 'PAYMENT',     response.transaction.type
    assert_equal 'T283mzh6EUc1yo5JJdwmPzA', response.trace
  end

  def test_submit_authorisation
    payload_with_deferred = request_payload
    payload_with_deferred[:transaction][:deferred] = true
    stub_api_post('transactions/1234/payment').
      with(body: payload_with_deferred).
      to_return(fixture("submit_authorisation.json"))

    response = @blue.submit_authorisation(**payment_payload)
    assert_equal 'AUTHORISED',  response.processing.auth_response.status
    assert_equal '10044236140', response.transaction.transaction_id
    assert_equal 'SUCCESS',     response.transaction.status
    assert_equal 'PREAUTH',     response.transaction.type
    assert_equal 'TCrwo0E9yjBrgCynkFdNlgw', response.trace
  end

  def test_capture_authorisation
    txn_id = '10044236140'
    stub_api_post("transactions/1234/#{txn_id}/capture").
      with(body: {}).
      to_return(fixture("capture_authorisation.json"))

    response = @blue.capture_authorisation(txn_id)
    assert_equal 'AUTHORISED',  response.processing.auth_response.status
    assert_equal '10044236205', response.transaction.transaction_id
    assert_equal 'SUCCESS',     response.transaction.status
    assert_equal 'CAPTURE',     response.transaction.type
    assert_equal txn_id,        response.transaction.related_transaction.transaction_id
    assert_equal 'xyz-1234',    response.transaction.related_transaction.merchant_ref
    assert_equal 'T0ymXgfPCRpCDyAlJneHOLw', response.trace
  end

  def test_cancel_authorisation
    txn_id = '10044236140'
    stub_api_post("transactions/1234/#{txn_id}/cancel").
      with(body: {}).
      to_return(fixture("cancel_authorisation.json"))

    response = @blue.cancel_authorisation(txn_id)
    assert_equal 'AUTHORISED',  response.processing.auth_response.status
    assert_equal '10044236207', response.transaction.transaction_id
    assert_equal 'SUCCESS',     response.transaction.status
    assert_equal 'CANCEL',      response.transaction.type
    assert_equal txn_id,        response.transaction.related_transaction.transaction_id
    assert_equal 'xyz-1234',    response.transaction.related_transaction.merchant_ref
    assert_equal 'T1N6taCE5T7sLmGXfVOy6Zw', response.trace
  end

  def test_get_transaction
    txn_id = '10044236139'
    stub_api_get("transactions/1234/#{txn_id}").
      to_return(fixture("request_transaction.json"))

    response = @blue.transaction(txn_id)
    assert_equal 'AUTHORISED',  response.processing.auth_response.status
    assert_equal '10044236139', response.transaction.transaction_id
    assert_equal 'xyz-1234',    response.transaction.merchant_ref
    assert_equal 'SUCCESS',     response.transaction.status
    assert_equal 'PAYMENT',     response.transaction.type
  end

  def test_refund_payment
    txn_id = '10044236139'
    stub_api_post("transactions/1234/#{txn_id}/refund").
      with(body: {}).
      to_return(fixture("refund_payment.json"))

    response = @blue.refund_payment(txn_id)
    assert_equal 'AUTHORISED',  response.processing.auth_response.status
    assert_equal '10044236208', response.transaction.transaction_id
    assert_equal 'SUCCESS',     response.transaction.status
    assert_equal 'REFUND',      response.transaction.type
    assert_equal txn_id,        response.transaction.related_transaction.transaction_id
    assert_equal 'xyz-1234',    response.transaction.related_transaction.merchant_ref
    assert_equal 'Tp5PlxA6TF_FvBpD7HhFrfA', response.trace
  end

  def test_partial_refund
    txn_id = '10044236140'
    amount = '3.49'
    stub_api_post("transactions/1234/#{txn_id}/refund").
      with(body: refund_request_payload(amount)).
      to_return(fixture("refund_payment_partial.json"))

    response = @blue.refund_payment(txn_id, amount: amount)
    assert_equal 'AUTHORISED',  response.processing.auth_response.status
    assert_equal '10044236217', response.transaction.transaction_id
    assert_equal 'SUCCESS',     response.transaction.status
    assert_equal 'REFUND',      response.transaction.type
    assert_equal 3.49,          response.transaction.amount
    assert_equal txn_id,        response.transaction.related_transaction.transaction_id
    assert_equal 'xyz-1234',    response.transaction.related_transaction.merchant_ref
    assert_equal 'TaEG0_5DaqtJjdtmq_-fs5Q', response.trace
  end

  def test_refund_failure
    txn_id = '10044236140'
    amount = '4.89'
    stub_api_post("transactions/1234/#{txn_id}/refund").
      with(body: refund_request_payload(amount)).
      to_return(fixture("refund_payment_failure.json"))

    error = assert_raises(PayPoint::Blue::Error::Validation) do
      @blue.refund_payment(txn_id, amount: amount)
    end
    assert_equal 'Amount exceeds amount refundable', error.message
    assert_equal 'V402', error.code
    assert_equal 'FAILED', error.response[:body].transaction.status
  end

  private

  def payment_payload
    {
      transaction: {
        merchant_ref: "xyz-1234",
        amount: "4.89",
      },
      customer: {
        merchant_ref: "42",
        display_name: "John Doe"
      },
      payment_method: {
        card: {
          pan: "9900000000005159",
          expiry_date: "1215",
          nickname: "primary card"
        }
      },
      locale: "en"
    }
  end

  def request_payload
    with_defaults = payment_payload.dup.tap do |hash|
      hash[:transaction] = hash[:transaction].merge currency: 'GBP', commerce_type: 'ECOM'
      hash[:callbacks] = { pre_auth_callback: { url: 'http://example.com/callback', format: 'REST_JSON' } }
    end
    camelcase_and_symbolize_keys(with_defaults)
  end

  def refund_request_payload(amount)
    camelcase_and_symbolize_keys transaction: {
      amount: amount,
      currency: 'GBP',
      commerce_type: 'ECOM'
    }
  end

end
