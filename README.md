# PayPoint::Blue

API client for PayPoint's 3rd generation PSP product a.k.a PayPoint Blue.

## Installation

Add this line to your application's Gemfile:

    gem 'paypoint-blue'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install paypoint-blue

## Usage

Read the [documentation](http://www.rubydoc.info/gems/paypoint-blue).

Run `bin/console` to start an interactive prompt for a playgound where
you can experiment with the API. You will have a bunch of meaningful
defaults set and some helpers to use. Just call the `help` or `h` method
in the console to learn more about the different helpers.

### Example

    # Endpoint can be the actual URL or one of :test or :live.
    # Installation id and credentials default to these ENV vars if omitted.
    blue = PayPoint::Blue.hosted_client(
      endpoint: :test,
      inst_id: ENV['BLUE_API_INSTALLATION'],
      api_id: ENV['BLUE_API_ID'],
      api_password: ENV['BLUE_API_PASSWORD'],
      defaults: {
        currency: "GBP",
        return_url: "http://example.com/callback/return",
        skin: "9001"
      }
    )

    blue.ping # => true

    result = blue.make_payment(
      merchant_ref: "abcd-1234",
      amount: "4.89",
      customer_ref: "42",
      customer_name: "Alice"
    )
    result.session_id # => "39ac..."
    result.redirect_url # => "https://hosted.paypoint.net/..."

    # The hosted product doesn't have this endpoint, but the client will delegate
    # this request to an API client for the regular API product behind the scenes.
    blue.transaction(transaction_id) # => { processing: { ... }, payment_method: { ... }, ... }

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/CPlus/paypoint-blue/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
