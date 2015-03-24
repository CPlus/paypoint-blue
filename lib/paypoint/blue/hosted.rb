require "forwardable"

require "paypoint/blue/base"

class PayPoint::Blue::Hosted < PayPoint::Blue::Base

  ENDPOINTS = {
    test: "https://hosted.mite.paypoint.net/hosted/rest",
    live: "https://hosted.paypoint.net/hosted/rest"
  }.freeze

  shortcut :merchant_ref,  'transaction.merchant_reference'
  shortcut :amount,        'transaction.money.amount.fixed'
  shortcut :currency,      'transaction.money.currency'
  shortcut :customer_ref,  'customer.identity.merchant_customer_id'
  shortcut :customer_name, 'customer.details.name'
  shortcut :return_url,    'session.return_url.url'
  shortcut :restore_url,   'session.restore_url.url'
  shortcut :skin,          'session.skin'

  shortcut :pre_auth_callback,        'session.pre_auth_callback.url'
  shortcut :post_auth_callback,       'session.post_auth_callback.url'
  shortcut :transaction_notification, 'session.transaction_notification.url'

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
  def make_payment(**payload)
    payload = build_payload(payload,
      defaults: %i[
        currency return_url restore_url skin
        pre_auth_callback post_auth_callback transaction_notification
      ]
    )
    client.post "sessions/#{inst_id}/payments", build_payload(payload)
  end

  # Submit an authorisation
  #
  # @see https://developer.paypoint.com/payments/docs/#payments/submit_an_authorisation
  #
  # This is a convenience method which makes a payment with the
  # transaction's `deferred` value set to `true`.
  #
  # @see #make_payment
  def submit_authorisation(**payload)
    payload[:transaction] ||= {}
    payload[:transaction][:deferred] = true
    make_payment(**payload)
  end

end
