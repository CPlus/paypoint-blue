require "paypoint/blue/error"

module PayPoint
  module Blue
    class RaiseErrors < Faraday::Response::Middleware

      def on_complete(env)
        outcome = fetch_outcome(env)
        if outcome
          case outcome['reasonCode']
          when /^S/ then return
          when /^V/ then raise ValidationError, response_values(env)
          when /^A/ then raise AuthError,       response_values(env)
          when /^C/ then raise CancelledError,  response_values(env)
          when /^X/ then raise ExternalError,   response_values(env)
          when /^U/ then raise SuspendedError,  response_values(env)
          else
            raise ClientError, response_values(env)
          end
        elsif env.status >= 400
          raise ClientError, response_values(env)
        end
      end

      private

      def fetch_outcome(env)
        env.body.is_a?(Hash) && env.body['outcome']
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
