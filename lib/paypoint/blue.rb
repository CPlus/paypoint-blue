require "paypoint/blue/version"
require "paypoint/blue/api"
require "paypoint/blue/hosted"
require "paypoint/blue/utils"

module PayPoint
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

  end
end
