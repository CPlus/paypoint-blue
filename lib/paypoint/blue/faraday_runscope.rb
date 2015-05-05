class FaradayRunscope < Faraday::Middleware

  CUSTOM_PORT = "Runscope-Request-Port".freeze

  def initialize(app, bucket, transform_paths: false)
    super(app)
    self.bucket = bucket
    self.transform_paths = Array(transform_paths)
  end

  def call(env)
    if env.url.port != env.url.default_port
      env.request_headers[CUSTOM_PORT] = env.url.port.to_s
      env.url.port = env.url.default_port
    end

    transform_url env.url

    if transform_paths && env.body.respond_to?(:each_with_index)
      transform_paths!(env.body)
    end

    @app.call env
  end

  protected

  attr_accessor :bucket, :transform_paths

  def transform_url(url)
    if url.respond_to?(:host=)
      url.host = runscope_host(url.host)
    elsif url.is_a?(String)
      uri = URI.parse(url)
      uri.host = runscope_host(uri.host)
      return uri.to_s
    end
    url
  end

  def runscope_host(host)
    "#{host.gsub('-', '--').tr('.', '-')}-#{bucket}.runscope.net"
  end

  def transform_paths!(enum, path=nil)
    each_pair(enum) do |key, value|
      key_path = path ? "#{path}.#{key}" : key.to_s
      if value.respond_to?(:each_with_index)
        transform_paths!(value, key_path)
      elsif transform_path?(key_path)
        enum[key] = transform_url(value)
      end
    end
  end

  def each_pair(enum)
    if enum.respond_to?(:each_pair)
      enum.each_pair do |key, value|
        yield key, value
      end
    else
      enum.each_with_index do |value, index|
        yield index, value
      end
    end
  end

  def transform_path?(path)
    transform_paths.any? do |path_to_transform|
      path_to_transform === path
    end
  end

end
