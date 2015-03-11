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
end
