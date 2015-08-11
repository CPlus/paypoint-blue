require "json"

require "hashie/mash"

require "paypoint/blue/version"
require "paypoint/blue/api"
require "paypoint/blue/hosted"
require "paypoint/blue/utils"

module PayPoint
  # Top level module with helper methods.
  module Blue
    # Creates a client for the PayPoint Blue API product
    #
    # @see PayPoint::Blue::Base#initialize
    def self.api_client(**options)
      PayPoint::Blue::API.new(**options)
    end

    # Creates a client for the PayPoint Blue Hosted product
    #
    # @see PayPoint::Blue::Base#initialize
    def self.hosted_client(**options)
      PayPoint::Blue::Hosted.new(**options)
    end

    # Parse a raw JSON PayPoint callback payload similarly to the
    # Faraday response middlewares set up in {PayPoint::Blue::Base}.
    #
    # @return [Hashie::Mash] the parsed, snake_cased response
    def self.parse_payload(json)
      payload = json.respond_to?(:read) ? json.read : json.to_s
      if payload.encoding == Encoding::ASCII_8BIT
        payload.force_encoding "iso-8859-1"
      end
      payload = JSON.parse(payload)
      payload = Utils.snakecase_and_symbolize_keys(payload)
      Hashie::Mash.new(payload)
    end
  end
end
