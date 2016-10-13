$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "paypoint/blue"

require "minitest/autorun"
require "webmock/minitest"

include PayPoint::Blue::Utils

def api_endpoint
  "https://api.mite.paypoint.net:2443/acceptor/rest/"
end

def hosted_endpoint
  "https://hosted.mite.paypoint.net/hosted/rest/"
end

def stub_api_get(path)
  stub_request(:get, api_endpoint + path).with(basic_auth: %w(ABC secret))
end

def stub_hosted_get(path)
  stub_request(:get, hosted_endpoint + path).with(basic_auth: %w(ABC secret))
end

def stub_api_post(path)
  stub_request(:post, api_endpoint + path).with(basic_auth: %w(ABC secret))
end

def stub_hosted_post(path)
  stub_request(:post, hosted_endpoint + path).with(basic_auth: %w(ABC secret))
end

def fixture(file)
  File.new(File.join(File.expand_path("../fixtures", __FILE__), file))
end
