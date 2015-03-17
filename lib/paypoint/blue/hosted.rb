require "forwardable"

require "paypoint/blue/base"

class PayPoint::Blue::Hosted < PayPoint::Blue::Base

  ENDPOINTS = {
    test: "https://hosted.mite.paypoint.net/hosted/rest",
    live: "https://hosted.paypoint.net/hosted/rest"
  }.freeze

  extend Forwardable

  def_delegators :@api_client,
    :capture_authorisation,
    :cancel_authorisation,
    :transaction,
    :refund_payment

  def initialize(**options)
    @api_client = PayPoint::Blue::API.new(**options)
    super
  end

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
  # @see https://developer.paypoint.com/payments/docs/#payments/make_a_payment
  #
  # All arguments will be merged into the final payload.
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

  # Submit an authorisation
  #
  # @see https://developer.paypoint.com/payments/docs/#payments/submit_an_authorisation
  #
  # This is a convenience method which makes a payment with the
  # transaction's `deferred` value set to `true`.
  #
  # @see #make_payment
  def submit_authorisation(transaction:, customer:, session:, **options)
    payload = options.merge transaction: transaction, customer: customer, session: session
    payload[:transaction][:deferred] = true
    make_payment(**payload)
  end

end
