module PayPoint
  module Blue

    class Error < StandardError
      attr_reader :response, :code

      def initialize(response)
        @response = response

        if outcome
          @code   = outcome['reasonCode']
          message = outcome['reasonMessage']
        else
          message = "the server responded with status #{response[:status]}"
        end

        super(message)
      end

      private

      def outcome
        @outcome ||= response[:body].is_a?(Hash) && response[:body]['outcome']
      end
    end

    %w( Client Validation Auth Cancelled External Suspended ).each do |type|
      self.const_set("#{type}Error", Class.new(Error))
    end

  end
end
