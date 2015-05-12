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
          case outcome[:reason_code]
          when /^S/ then return
          when /^V/ then raise Error::Validation, response_values(env)
          when /^A/ then raise Error::Auth,       response_values(env)
          when /^C/ then raise Error::Cancelled,  response_values(env)
          when /^X/ then raise Error::External,   response_values(env)
          when /^U/ then raise Error::Suspended,  response_values(env)
          else
            raise Error::Client, response_values(env)
          end
        elsif not_found?(env)
          raise Error::NotFound, response_values(env)
        elsif client_error?(env)
          raise Error::Client, response_values(env)
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

      def response_values(env)
        {
          status:  env.status,
          headers: env.response_headers,
          body:    env.body
        }
      end
    end
  end
end
