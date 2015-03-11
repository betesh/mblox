require "mblox"
require "yaml"

CONFIG = YAML::load(File.open('config.yml'))

def set_configuration
  Mblox.configure do |config|
    config.outbound_url = CONFIG['outbound_url']
    config.profile_id = CONFIG['profile_id']
    config.sender_id = CONFIG['sender_id']
    config.password = CONFIG['password']
    config.partner_name = CONFIG['partner_name']
    config.tariff = CONFIG['tariff']
    config.service_id = CONFIG['service_id']
  end
end

TEST_NUMBER = CONFIG['test_number']
LANDLINE = 6176354500

module Mblox
  class << self
    def reset_configuration
      @config = nil
    end
  end
end

RSpec.configure do |config|
  config.order = "random"
end
