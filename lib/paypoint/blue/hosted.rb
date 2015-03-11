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

  # Make a payment
  #
  # All arguments will be merged into the final payload. For details on
  # what to include, see https://developer.paypoint.com/payments/docs/#payments/make_a_payment
  #
  # @param [Hash] transaction details of the transaction you want to create
  # @param [Hash] customer identity and details about the customer
  # @param [Hash] session returnUrl, callbacks and skin
  #
  # @return [Hash] the API response
  def make_payment(transaction:, customer:, session:, **options)
    payload = options.merge transaction: transaction, customer: customer, session: session
    client.post "sessions/#{inst_id}/payments", payload
  end

end
