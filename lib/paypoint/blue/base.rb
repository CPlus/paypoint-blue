require "faraday"
require "faraday_middleware"

require "paypoint/blue/payload_builder"
require "paypoint/blue/body_extractor"
require "paypoint/blue/hash_key_converter"
require "paypoint/blue/raise_errors"
require "paypoint/blue/faraday_runscope"

module PayPoint
  module Blue
    # Abstract base class for the API clients. Takes care of
    # initializing the Faraday client by setting up middlewares in the
    # right order.
    #
    # The base class doesn't implement any of the API interface methods,
    # but leaves that to the subclasses.
    #
    # @note All payloads expected by the API interface methods in the
    #   subclasses will be processed by {PayloadBuilder} and the
    #   {HashKeyConverter} middleware. Shortcuts will be moved to their
    #   proper paths, default values will be applied, and snakecase keys
    #   will be converted to camelcase.
    #
    # @abstract
    class Base
      include PayloadBuilder

      # The Faraday client
      attr_reader :client

      # Creates a PayPoint Blue API client
      #
      # Options not listed here will be passed on to the Faraday client.
      #
      # @param endpoint +:test+, +:live+, or a string with the API
      #   endpoint URL
      # @param inst_id the ID for your installation as provided by
      #   PayPoint
      # @param api_id your API user ID
      # @param api_password your API user password
      #
      # @option options [Hash] :defaults default payload values; see the
      #   documentation of the methods of {API} and {Hosted} for the
      #   payload keys that can have defaults
      # @option options [true,false] :log whether to log requests and
      #   responses
      # @option options [Logger] :logger a custom logger instance,
      #   implies +log: true+
      # @option options [true,false] :raw whether to return the raw
      #   +Faraday::Response+ object instead of a parsed value
      # @option options [String] :runscope when used, all traffic will
      #   pass through the provided {https://www.runscope.com/ Runscope}
      #   bucket, including notification callbacks
      # @option options [Integer] :timeout waiting for response in seconds
      # @option options [Integer] :open_timeout waiting for opening a connection
      #   in seconds
      def initialize(endpoint:, inst_id: ENV["BLUE_API_INSTALLATION"],
        api_id: ENV["BLUE_API_ID"], api_password: ENV["BLUE_API_PASSWORD"],
        **options)

        @endpoint     = get_endpoint_or_override_with(endpoint)
        @inst_id      = inst_id or fail ArgumentError, "missing inst_id"
        @api_id       = api_id or fail ArgumentError, "missing api_id"
        @api_password =
          api_password or fail ArgumentError, "missing api_password"

        self.defaults = options.delete(:defaults)
        @options = options.merge(url: @endpoint, **request_timeouts(options))
        @client = build_client
      end

      private

      attr_reader :inst_id, :options

      def get_endpoint_or_override_with(endpoint)
        self.class.const_get("ENDPOINTS").fetch(endpoint, endpoint.to_s)
      end

      def request_timeouts(timeout_options)
        {
          request: {
            open_timeout: timeout_options[:open_timeout] || 2,
            timeout:      timeout_options[:timeout]      || 5,
          }
        }
      end

      def client_options
        options.select { |k, _| Faraday::ConnectionOptions.members.include?(k) }
      end

      def build_client # rubocop:disable AbcSize, MethodLength
        Faraday.new(client_options) do |f|
          unless options[:raw]
            # This extracts the body and discards all other data from the
            # Faraday::Response object. It should be placed here before
            # all response middlewares, so that it runs as the last one.
            f.use PayPoint::Blue::BodyExtractor
          end

          f.use PayPoint::Blue::RaiseErrors
          unless options[:raw]
            f.response :mashify
            f.use PayPoint::Blue::HashKeyConverter
          end
          f.response :json, content_type: /\bjson$/
          if options[:logger] || options[:log]
            f.response :logger, options[:logger], { headers: true, bodies: true }
          end

          # This sends all API traffic through Runscope, including
          # notifications. It needs to be inserted here before the JSON
          # request middleware so that it is able to transform
          # notification URLs too.
          if options[:runscope]
            path_re = /\A(callbacks|session)\.\w+(Callback|Notification)\.url\Z/
            f.use FaradayRunscope, options[:runscope], transform_paths: path_re
          end

          f.request :basic_auth, @api_id, @api_password
          f.request :json

          f.adapter Faraday.default_adapter
        end
      end
    end
  end
end
