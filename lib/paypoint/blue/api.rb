require "paypoint/blue/base"

# Client class for the API product.
class PayPoint::Blue::API < PayPoint::Blue::Base

  ENDPOINTS = {
    test: "https://api.mite.paypoint.net:2443/acceptor/rest",
    live: "https://api.paypoint.net/acceptor/rest",
  }.freeze

  shortcut :merchant_ref,  'transaction.merchant_ref'
  shortcut :amount,        'transaction.amount'
  shortcut :currency,      'transaction.currency'
  shortcut :commerce_type, 'transaction.commerce_type'
  shortcut :customer_ref,  'customer.merchant_ref'
  shortcut :customer_name, 'customer.display_name'

  shortcut :pre_auth_callback,        'callbacks.pre_auth_callback.url'
  shortcut :post_auth_callback,       'callbacks.post_auth_callback.url'
  shortcut :transaction_notification, 'callbacks.transaction_notification.url'
  shortcut :expiry_notification,      'callbacks.expiry_notification.url'

  # Test connectivity
  #
  # @return [true,false]
  def ping
    client.get "transactions/ping"
    true
  rescue Faraday::ClientError
    false
  end

  # Make a payment
  #
  # @api_url https://developer.paypoint.com/payments/docs/#payments/make_a_payment
  #
  # @applies_defaults
  #   +:currency+, +:commerce_type+, +:pre_auth_callback+,
  #   +:post_auth_callback+, +:transaction_notification+,
  #   +:expiry_notification+
  #
  # @param [Hash] payload the payload is made up of the keyword
  #   arguments passed to the method
  #
  # @return the API response
  def make_payment(**payload)
    payload = build_payload(payload,
      defaults: %i[
        currency commerce_type pre_auth_callback post_auth_callback
        transaction_notification expiry_notification
      ]
    )
    client.post "transactions/#{inst_id}/payment", payload
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

  # Capture an authorisation
  #
  # @api_url https://developer.paypoint.com/payments/docs/#payments/capture_an_authorisation
  #
  # @applies_defaults +:commerce_type+
  #
  # @param [String] transaction_id the id of the previous transaction
  # @param [Hash] payload the payload is made up of the keyword
  #   arguments passed to the method
  #
  # @return the API response
  def capture_authorisation(transaction_id, **payload)
    payload = build_payload(payload, defaults: %i[commerce_type])
    client.post "transactions/#{inst_id}/#{transaction_id}/capture", payload
  end

  # Cancel an authorisation
  #
  # @api_url https://developer.paypoint.com/payments/docs/#payments/cancel_an_authorisation
  #
  # @applies_defaults +:commerce_type+
  #
  # @param (see #capture_authorisation)
  #
  # @return the API response
  def cancel_authorisation(transaction_id, **payload)
    payload = build_payload(payload, defaults: %i[commerce_type])
    client.post "transactions/#{inst_id}/#{transaction_id}/cancel", payload
  end

  # Get transaction details
  #
  # @api_url https://developer.paypoint.com/payments/docs/#payments/request_a_previous_transaction
  #
  # @param [String] transaction_id the id of the transaction
  #
  # @return the API response
  def transaction(transaction_id)
    client.get "transactions/#{inst_id}/#{transaction_id}"
  end

  # Refund a payment
  #
  # @api_url https://developer.paypoint.com/payments/docs/#payments/refund_a_payment
  #
  # Without a payload this will refund the full amount. If you only want
  # to refund a smaller amount, you will need to pass either the
  # +amount+ or a +transaction+ hash as a keyword argument.
  #
  # @example Partial refund
  #   blue.refund_payment(txn_id, amount: '3.49') # assumes currency set as default
  #
  # @param (see #capture_authorisation)
  #
  # @return the API response
  def refund_payment(transaction_id, **payload)
    defaults = payload[:amount] || payload[:transaction] && payload[:transaction][:amount] ? %i[currency commerce_type] : []
    payload = build_payload(payload, defaults: defaults)
    client.post "transactions/#{inst_id}/#{transaction_id}/refund", payload
  end

end
