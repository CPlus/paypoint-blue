$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "paypoint/blue"

require "minitest/autorun"
require "webmock/minitest"

include PayPoint::Blue::Utils

def api_endpoint
  "https://api.mite.pay360.com/acceptor/rest/"
end

def hosted_endpoint
  "https://api.mite.pay360.com/hosted/rest/"
end

def stub_api_get(path)
  call_stub_request(:get, api_endpoint + path)
end

def stub_hosted_get(path)
  call_stub_request(:get, hosted_endpoint + path)
end

def stub_api_post(path)
  call_stub_request(:post, api_endpoint + path)
end

def stub_hosted_post(path)
  call_stub_request(:post, hosted_endpoint + path)
end

def stub_hosted_put(path)
  call_stub_request(:put, hosted_endpoint + path)
end

def call_stub_request(method, url)
  stub_request(method, url).with(basic_auth: %w(ABC secret))
end

def fixture(file)
  File.new(File.join(File.expand_path("../fixtures", __FILE__), file))
end
