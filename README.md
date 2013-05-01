# Mblox

This gem is for subscribers to Mblox to send SMS messages.

## Installation

Add this line to your application's Gemfile:

    gem 'mblox'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mblox

## Usage

Configuration

    Mblox.configure do |config|
      # Set all of these values, provided to you in your Mblox subscription
      config.outbound_url = ...
      config.profile_id = ...
      config.sender_id = ...
      config.password = ...
      config.partner_name = ...
      config.tariff = ...
      config.service_id = ...
      
      # You can also configure some logging options
      # In a Rails environment, config.logger will default to Rails.logger and config.log_at will default to :debug
      # config.log_at means the level at which Mblox will log.
      # If config.log_at == :debug and your logger's log level is :info, logging will be suppressed because it is below the log level of the logger.
      config.logger = Logger.new(STDOUT)
      config.log_at :info
    end

Once your application is configured, send messages:

    phone_number = 2225555555 # The number you're sending to.  Must be a 10-digit number, including the area code.  Can be a String or Fixnum.
    Mblox::Sms.new(phone_number, "your message").send

## Testing

Copy config.yml.example to config.yml and set all the values in that file.  Run:

    rspec

You should recieve 2 SMS messages to your phone within several seconds.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
