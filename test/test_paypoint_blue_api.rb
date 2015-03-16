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

  def test_capture_authorisation
    txn_id = '10044236140'
    stub_api_post("transactions/1234/#{txn_id}/capture").with(body: {}).to_return(fixture("capture_authorisation.json"))
    response = @blue.capture_authorisation(txn_id)
    assert_equal 'AUTHORISED',  response['processing']['authResponse']['status']
    assert_equal '10044236205', response['transaction']['transactionId']
    assert_equal 'SUCCESS',     response['transaction']['status']
    assert_equal 'CAPTURE',     response['transaction']['type']
    assert_equal txn_id,        response['transaction']['relatedTransaction']['transactionId']
    assert_equal 'xyz-1234',    response['transaction']['relatedTransaction']['merchantRef']
    assert_equal 'T0ymXgfPCRpCDyAlJneHOLw', response['trace']
  end

  def test_cancel_authorisation
    txn_id = '10044236140'
    stub_api_post("transactions/1234/#{txn_id}/cancel").with(body: {}).to_return(fixture("cancel_authorisation.json"))
    response = @blue.cancel_authorisation(txn_id)
    assert_equal 'AUTHORISED',  response['processing']['authResponse']['status']
    assert_equal '10044236207', response['transaction']['transactionId']
    assert_equal 'SUCCESS',     response['transaction']['status']
    assert_equal 'CANCEL',      response['transaction']['type']
    assert_equal txn_id,        response['transaction']['relatedTransaction']['transactionId']
    assert_equal 'xyz-1234',    response['transaction']['relatedTransaction']['merchantRef']
    assert_equal 'T1N6taCE5T7sLmGXfVOy6Zw', response['trace']
  end

  def test_get_transaction
    txn_id = '10044236139'
    stub_api_get("transactions/1234/#{txn_id}").to_return(fixture("request_transaction.json"))
    response = @blue.transaction(txn_id)
    assert_equal 'AUTHORISED',  response['processing']['authResponse']['status']
    assert_equal '10044236139', response['transaction']['transactionId']
    assert_equal 'xyz-1234',    response['transaction']['merchantRef']
    assert_equal 'SUCCESS',     response['transaction']['status']
    assert_equal 'PAYMENT',     response['transaction']['type']
  end

  def test_refund_payment
    txn_id = '10044236139'
    stub_api_post("transactions/1234/#{txn_id}/refund").with(body: {}).to_return(fixture("refund_payment.json"))
    response = @blue.refund_payment(txn_id)
    assert_equal 'AUTHORISED',  response['processing']['authResponse']['status']
    assert_equal '10044236208', response['transaction']['transactionId']
    assert_equal 'SUCCESS',     response['transaction']['status']
    assert_equal 'REFUND',      response['transaction']['type']
    assert_equal txn_id,        response['transaction']['relatedTransaction']['transactionId']
    assert_equal 'xyz-1234',    response['transaction']['relatedTransaction']['merchantRef']
    assert_equal 'Tp5PlxA6TF_FvBpD7HhFrfA', response['trace']
  end

  def test_partial_refund
    txn_id = '10044236140'
    payload = { transaction: { amount: "3.49", currency: "GBP" } }
    stub_api_post("transactions/1234/#{txn_id}/refund").with(body: payload).to_return(fixture("refund_payment_partial.json"))
    response = @blue.refund_payment(txn_id, **payload)
    assert_equal 'AUTHORISED',  response['processing']['authResponse']['status']
    assert_equal '10044236217', response['transaction']['transactionId']
    assert_equal 'SUCCESS',     response['transaction']['status']
    assert_equal 'REFUND',      response['transaction']['type']
    assert_equal 3.49,          response['transaction']['amount']
    assert_equal txn_id,        response['transaction']['relatedTransaction']['transactionId']
    assert_equal 'xyz-1234',    response['transaction']['relatedTransaction']['merchantRef']
    assert_equal 'TaEG0_5DaqtJjdtmq_-fs5Q', response['trace']
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
