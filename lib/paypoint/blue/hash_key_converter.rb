module PayPoint
  module Blue

    # Faraday middleware for converting hash keys in the request payload
    # from snake_case to camelCase and the other way around in the
    # response.
    class HashKeyConverter < Faraday::Middleware

      # Convert hash keys to camelCase in the request and to snake_case
      # in the response
      def call(env)
        if env.body.is_a?(Enumerable)
          env.body = Utils.camelcase_and_symbolize_keys(env.body)
        end

        @app.call(env).on_complete do |response_env|
          if response_env.body.is_a?(Enumerable)
            response_env.body = Utils.snakecase_and_symbolize_keys(response_env.body)
          end
        end
      end
    end
  end
end
