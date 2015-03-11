require "faraday"
require "faraday_middleware"

module PayPoint
  module Blue
    class Base

      attr_reader :client, :inst_id

      # Creates a PayPoint Blue API client.
      #
      # @param endpoint `:test`, `:live`, or a string with the API endpoint URL
      # @param inst_id the ID for your installation as provided by PayPoint,
      #   defaults to `ENV['BLUE_API_INSTALLATION']`
      # @param api_id your API user ID, defaults to `ENV['BLUE_API_ID']`
      # @param api_password your API user password, defaults to `ENV['BLUE_API_PASSWORD']`
      # @param options the client may receive the following options
      #   * `:log` [true/false] – whether to log requests and responses
      #   * `:logger` [Logger] – a custom logger instance, implies `log: true`
      #   * `:raw` [true/false] – whether to return the raw Faraday::Response object instead of a parsed value
      #   * any other options are passed on to the Faraday client
      def initialize(endpoint:,
                     inst_id: ENV['BLUE_API_INSTALLATION'],
                     api_id: ENV['BLUE_API_ID'],
                     api_password: ENV['BLUE_API_PASSWORD'],
                     **options)

        @endpoint = self.class.const_get('ENDPOINTS').fetch(endpoint, endpoint.to_s)

        @inst_id      = inst_id or raise ArgumentError, "missing inst_id"
        @api_id       = api_id or raise ArgumentError, "missing api_id"
        @api_password = api_password or raise ArgumentError, "missing api_password"

        options[:url] = @endpoint
        @options = options

        @client = build_client
      end

      private

      attr_reader :options

      def client_options
        options.select { |k,v| Faraday::ConnectionOptions.members.include?(k) }
      end

      def build_client
        Faraday.new(client_options) do |f|
          f.request :basic_auth, @api_id, @api_password
          f.request :json

          f.response :dates
          f.response :json, content_type: /\bjson$/
          f.response :logger, options[:logger] if options[:logger] || options[:log]
          f.response :raise_error

          f.adapter Faraday.default_adapter
        end
      end
    end
  end
end
