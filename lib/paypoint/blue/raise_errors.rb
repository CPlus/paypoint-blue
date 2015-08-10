require "paypoint/blue/error"

module PayPoint
  module Blue
    # Faraday response middleware for handling various error scenarios
    class RaiseErrors < Faraday::Response::Middleware
      # Raise an error if the response outcome signifies a failure or
      # the HTTP status code is 400 or greater.
      #
      # @raise [Error::Validation] for an outcome code starting with +V+
      # @raise [Error::Auth]       for an outcome code starting with +A+
      # @raise [Error::Cancelled]  for an outcome code starting with +C+
      # @raise [Error::External]   for an outcome code starting with +X+
      # @raise [Error::Suspended]  for an outcome code starting with +U+
      # @raise [Error::Client]     for all other error scenarios
      def on_complete(env)
        outcome = fetch_outcome(env)
        if outcome
          return if outcome[:reason_code] =~ /^S/
          fail error_from_outcome(outcome[:reason_code], response_values(env))
        elsif not_found?(env)
          fail Error::NotFound, response_values(env)
        elsif client_error?(env)
          fail Error::Client, response_values(env)
        end
      end

      private

      def not_found?(env)
        env.status == 404 && env.body[:reason_code] == "A400"
      end

      def client_error?(env)
        env.status >= 400
      end

      def fetch_outcome(env)
        env.body.is_a?(Hash) && env.body[:outcome]
      end

      def error_from_outcome(code, response_values)
        case code
        when /^V/ then Error::Validation.new(response_values)
        when /^A/ then Error::Auth.new(response_values)
        when /^C/ then Error::Cancelled.new(response_values)
        when /^X/ then Error::External.new(response_values)
        when /^U/ then Error::Suspended.new(response_values)
        else
          Error::Client.new(response_values)
        end
      end

      def response_values(env)
        {
          status:  env.status,
          headers: env.response_headers,
          body:    env.body,
        }
      end
    end
  end
end
