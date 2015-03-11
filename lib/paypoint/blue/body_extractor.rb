module PayPoint
  module Blue
    class BodyExtractor < Faraday::Middleware

      def call(env)
        response = @app.call(env)
        response.env[:body]
      end

    end
  end
end
