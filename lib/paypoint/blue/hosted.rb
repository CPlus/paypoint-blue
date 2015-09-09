require "forwardable"

require "paypoint/blue/base"

# Client class for the Hosted product.
class PayPoint::Blue::Hosted < PayPoint::Blue::Base
  ENDPOINTS = {
    test: "https://hosted.mite.paypoint.net/hosted/rest",
    live: "https://hosted.paypoint.net/hosted/rest",
  }.freeze

  shortcut :merchant_ref,  "transaction.merchant_reference"
  shortcut :amount,        "transaction.money.amount.fixed"
  shortcut :currency,      "transaction.money.currency"
  shortcut :commerce_type, "transaction.commerce_type"
  shortcut :description,   "transaction.description"
  shortcut :customer_ref,  "customer.identity.merchant_customer_id"
  shortcut :customer_name, "customer.details.name"
  shortcut :return_url,    "session.return_url.url"
  shortcut :cancel_url,    "session.cancel_url.url"
  shortcut :restore_url,   "session.restore_url.url"
  shortcut :skin,          "session.skin"

  shortcut :pre_auth_callback,        "session.pre_auth_callback.url"
  shortcut :post_auth_callback,       "session.post_auth_callback.url"
  shortcut :transaction_notification, "session.transaction_notification.url"

  extend Forwardable

  def_delegators :@api_client,
    :capture_authorisation,
    :cancel_authorisation,
    :transaction,
    :transactions_by_ref,
    :refund_payment,
    :customer,
    :customer_by_ref,
    :customer_payment_methods,
    :customer_payment_method

  # The Hosted product has only a few endpoints. However, users most
  # likey will want to access the endpoints of the API product as well.
  # Therefore, this class also delegates to an API client which is
  # initialized using the same options that this object receives.
  def initialize(**options)
    @api_client = PayPoint::Blue::API.new(**options)
    super
  end

  # Test connectivity
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
  # @api_url https://developer.paypoint.com/payments/docs/#payments/make_a_payment
  #
  # @applies_defaults
  #   +:currency+, +:commerce_type+, +:return_url+, +:cancel_url+,
  #   +:restore_url+, +:skin+, +:pre_auth_callback+, +:post_auth_callback+,
  #   +:transaction_notification+
  #
  # @param [Hash] payload the payload is made up of the keyword
  #   arguments passed to the method
  #
  # @return the API response
  def make_payment(**payload)
    payload = build_payload payload, defaults: %i(
      currency commerce_type return_url cancel_url restore_url skin
      pre_auth_callback post_auth_callback transaction_notification
    )
    client.post "sessions/#{inst_id}/payments", build_payload(payload)
  end

  # Submit an authorisation
  #
  # @api_url https://developer.paypoint.com/payments/docs/#payments/submit_an_authorisation
  # @see #make_payment
  #
  # This is a convenience method which makes a payment with the
  # transaction's +deferred+ value set to +true+.
  #
  # @param (see #make_payment)
  #
  # @return the API response
  def submit_authorisation(**payload)
    payload[:transaction] ||= {}
    payload[:transaction][:deferred] = true
    make_payment(**payload)
  end

  # Submit a payout
  #
  # @api_url https://developer.paypoint.com/payments/docs/#payments/submit_a_payout
  #
  # @applies_defaults
  #   +:currency+, +:commerce_type+, +:return_url+, +:cancel_url+,
  #   +:restore_url+, +:skin+, +:pre_auth_callback+, +:post_auth_callback+,
  #   +:transaction_notification+
  #
  # @param [Hash] payload the payload is made up of the keyword
  #   arguments passed to the method
  #
  # @return the API response
  def submit_payout(**payload)
    payload = build_payload payload, defaults: %i(
      currency commerce_type return_url cancel_url restore_url skin
      pre_auth_callback post_auth_callback transaction_notification
    )
    client.post "sessions/#{inst_id}/payouts", build_payload(payload)
  end

  # Manage Cards
  #
  # @api_url https://developer.paypoint.com/payments/docs/#customers/update_customer_cards
  #
  # @applies_defaults +:skin+
  #
  # @param [Hash] payload the payload is made up of the keyword
  #   arguments passed to the method
  #
  # @return the API response
  def manage_cards(**payload)
    payload = build_payload payload, defaults: %i(skin)
    client.post "sessions/#{inst_id}/cards", build_payload(payload)
  end
end
