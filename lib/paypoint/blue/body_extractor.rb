module PayPoint
  module Blue
    # Faraday middleware which extracts the body from the response
    # object and returns with just that discarding all other meta
    # information.
    class BodyExtractor < Faraday::Middleware
      # Extract and return just the body discarding everything else
      def call(env)
        response = @app.call(env)
        response.env[:body]
      end
    end
  end
end
