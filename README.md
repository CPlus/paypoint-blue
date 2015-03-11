# PayPoint::Blue

API client for PayPoint's 3rd generation PSP product a.k.a PayPoint Blue.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'paypoint-blue'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install paypoint-blue

## Usage

``` ruby
# endpoint can be the actual URL or one of :mite_api, :mite_hosted, :live_api, or :live_hosted
# installation id and credentials default to these ENV vars if omitted
blue = PayPoint::Blue.hosted_client(
  endpoint: :test,
  inst_id: ENV['BLUE_API_INSTALLATION'],
  api_id: ENV['BLUE_API_ID'],
  api_password: ENV['BLUE_API_PASSWORD']
)

blue.ping # => :ok

blue.transaction(transaction_id) # => { processing: { ... }, paymentMethod: { ... }, ... }
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/CPlus/paypoint-blue/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
