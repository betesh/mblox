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
      # For instance, if config.log_at == :debug, Mblox will log only if the logger's log level is :debug
      # Note that if config.log_at == :debug and your logger's log level is :info,
      #   logging will be suppressed because it is below the log level of the logger.
      config.logger = Logger.new(STDOUT)
      config.log_at :info

      # What to do if messages are longer than 160 characters.  Default is :raise_error
      # Other options are :truncate and :split
      config.on_message_too_long = :truncate
    end

Once your application is configured, send messages:

    # The number to sending to must be a 10-digit number, including the area code.  Can be a String or Fixnum.
    phone_number = 2225555555 # or: phone_number = "2225555555"
    Mblox::Sms.new(phone_number, "your message").send

## Testing

Copy config.yml.example to config.yml and set all the values in that file.  Run:

    rspec

You should recieve 5 SMS messages to your phone within several seconds.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
