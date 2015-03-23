require "paypoint/blue/base"

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

  # Test connectivity.
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
  # @see https://developer.paypoint.com/payments/docs/#payments/make_a_payment
  #
  # All arguments will be merged into the final payload.
  #
  # @param [Hash] transaction details of the transaction you want to create
  # @param [Hash] customer identity and details about the customer
  # @param [Hash] payment_method card details, billing address
  #
  # @return [Hash] the API response
  def make_payment(**payload)
    client.post "transactions/#{inst_id}/payment", self.class.build_payload(payload)
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

  # Capture an authorisation
  #
  # @see https://developer.paypoint.com/payments/docs/#payments/capture_an_authorisation
  #
  # @param [String] transaction_id transaction id of the previously
  #   submitted authorisation
  #
  # @return [Hash] the API response
  def capture_authorisation(transaction_id, **payload)
    client.post "transactions/#{inst_id}/#{transaction_id}/capture", self.class.build_payload(payload)
  end

  # Cancel an authorisation
  #
  # @see https://developer.paypoint.com/payments/docs/#payments/cancel_an_authorisation
  #
  # @param [String] transaction_id transaction id of the previously
  #   submitted authorisation
  #
  # @return [Hash] the API response
  def cancel_authorisation(transaction_id, **payload)
    client.post "transactions/#{inst_id}/#{transaction_id}/cancel", self.class.build_payload(payload)
  end

  # Get transaction details
  #
  # @see https://developer.paypoint.com/payments/docs/#payments/request_a_previous_transaction
  #
  # @param [String] transaction_id the id of the transaction
  #
  # @return [Hash] the API response
  def transaction(transaction_id)
    client.get "transactions/#{inst_id}/#{transaction_id}"
  end

  # Refund a payment
  #
  # @see https://developer.paypoint.com/payments/docs/#payments/refund_a_payment
  #
  # Without a payload this will refund the full amount. If you only want
  # to refund a smaller amount, you will need to pass a transaction
  # object.
  #
  # @example Partial refund
  #   blue.refund_payment(txn_id, transaction: { amount: '3.49' })
  #
  # @param [String] transaction_id the id of the transaction
  #
  # @return [Hash] the API response
  def refund_payment(transaction_id, **payload)
    client.post "transactions/#{inst_id}/#{transaction_id}/refund", self.class.build_payload(payload)
  end

end
