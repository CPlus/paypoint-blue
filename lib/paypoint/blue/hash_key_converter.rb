module PayPoint
  module Blue
    class HashKeyConverter < Faraday::Middleware

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
