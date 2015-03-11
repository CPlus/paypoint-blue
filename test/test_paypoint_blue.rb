require 'minitest_helper'

class TestPayPointBlue < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::PayPoint::Blue::VERSION
  end

  def test_api_client
    blue = PayPoint::Blue.api_client(endpoint: :test, inst_id: '123', api_id: 'ABC', api_password: 'secret')
    refute_nil blue.client
    assert_instance_of PayPoint::Blue::API, blue
  end

  def test_hosted_client
    blue = PayPoint::Blue.hosted_client(endpoint: :test, inst_id: '123', api_id: 'ABC', api_password: 'secret')
    refute_nil blue.client
    assert_instance_of PayPoint::Blue::Hosted, blue
  end
end
