require "paypoint/blue/base"

class PayPoint::Blue::API < PayPoint::Blue::Base

  ENDPOINTS = {
    test: "https://api.mite.paypoint.net:2443/acceptor/rest",
    live: "https://api.paypoint.net/acceptor/rest",
  }.freeze

  # Test connectivity.
  #
  # @return [true,false]
  def ping
    client.get "transactions/ping"
    true
  rescue Faraday::ClientError
    false
  end

end
