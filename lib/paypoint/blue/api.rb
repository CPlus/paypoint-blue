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

  # Make a payment
  #
  # @see https://developer.paypoint.com/payments/docs/#payments/make_a_payment
  #
  # All arguments will be merged into the final payload.
  #
  # @param [Hash] transaction details of the transaction you want to create
  # @param [Hash] customer identity and details about the customer
  # @param [Hash] paymentMethod card details, billing address
  #
  # @return [Hash] the API response
  def make_payment(transaction:, customer:, paymentMethod:, **options)
    payload = options.merge transaction: transaction, customer: customer, paymentMethod: paymentMethod
    client.post "transactions/#{inst_id}/payment", payload
  end

  # Submit an authorisation
  #
  # @see https://developer.paypoint.com/payments/docs/#payments/submit_an_authorisation
  #
  # This is a convenience method which makes a payment with the
  # transaction's `deferred` value set to `true`.
  #
  # @see #make_payment
  def submit_authorisation(transaction:, customer:, paymentMethod:, **options)
    payload = options.merge transaction: transaction, customer: customer, paymentMethod: paymentMethod
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
    client.post "transactions/#{inst_id}/#{transaction_id}/capture", payload
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
    client.post "transactions/#{inst_id}/#{transaction_id}/cancel", payload
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
    client.post "transactions/#{inst_id}/#{transaction_id}/refund", payload
  end

end
