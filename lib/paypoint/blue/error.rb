module PayPoint
  module Blue

    # Abstract error base class
    # @abstract
    class Error < StandardError

      # the response that caused the error
      attr_reader :response

      # the outcome code (e.g. +'V402'+)
      attr_reader :code

      # Initializes the error from the response object. It uses the
      # outcome message from the response if set.
      def initialize(response)
        @response = response

        if outcome
          @code   = outcome[:reason_code]
          message = outcome[:reason_message]
        else
          message = "the server responded with status #{response[:status]}"
        end

        super(message)
      end

      private

      def outcome
        @outcome ||= response[:body].is_a?(Hash) && response[:body][:outcome]
      end

      # Generic client error class, also a base class for more specific
      # types of errors
      class Client < Error; end

      # Specific error class for errors with a +'V'+ outcome code
      class Validation < Error; end

      # Specific error class for errors with an +'A'+ outcome code
      class Auth < Error; end

      # Specific error class for errors with a +'C'+ outcome code
      class Cancelled < Error; end

      # Specific error class for errors with a +'X'+ outcome code
      class External < Error; end

      # Specific error class for errors with an +'U'+ outcome code
      class Suspended < Error; end

    end

  end
end
