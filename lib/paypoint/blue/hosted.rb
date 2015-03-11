require "paypoint/blue/base"

class PayPoint::Blue::Hosted < PayPoint::Blue::Base

  ENDPOINTS = {
    test: "https://hosted.mite.paypoint.net/hosted/rest",
    live: "https://hosted.paypoint.net/hosted/rest"
  }.freeze

  # Test connectivity.
  #
  # @return [true,false]
  def ping
    client.get "sessions/ping"
    true
  rescue Faraday::ClientError
    false
  end

end
