require "minitest_helper"

class TestPayPointBlue < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::PayPoint::Blue::VERSION
  end

  def test_api_client
    blue = PayPoint::Blue.api_client(endpoint: :test, inst_id: "123", api_id: "ABC", api_password: "secret")
    refute_nil blue.client
    assert_instance_of PayPoint::Blue::API, blue
  end

  def test_hosted_client
    blue = PayPoint::Blue.hosted_client(endpoint: :test, inst_id: "123", api_id: "ABC", api_password: "secret")
    refute_nil blue.client
    assert_instance_of PayPoint::Blue::Hosted, blue
  end

  def test_parse_payload
    json_payload = fixture("callback_payload.json")
    parsed_payload = PayPoint::Blue.parse_payload(json_payload)
    assert_equal "CARD",        parsed_payload.payment_method.payment_class
    assert_equal "alice",       parsed_payload.customer.merchant_ref
    assert_equal "10044237432", parsed_payload.transaction.transaction_id
    assert_equal "alice-1",     parsed_payload.transaction.merchant_ref
    assert_equal "SUCCESS",     parsed_payload.transaction.status
    assert_equal "PAYMENT",     parsed_payload.transaction.type
    assert_equal 4.99,          parsed_payload.transaction.amount
    assert_equal "f2f53629-da95-420a-9580-8649d05ad7db", parsed_payload.session_id
  end
end
