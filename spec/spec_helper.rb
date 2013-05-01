require "mblox"
require "yaml"

yaml = YAML::load(File.open('config.yml'))

Mblox.configure do |config|
  config.outbound_url = yaml['outbound_url']
  config.profile_id = yaml['profile_id']
  config.sender_id = yaml['sender_id']
  config.password = yaml['password']
  config.partner_name = yaml['partner_name']
  config.tariff = yaml['tariff']
  config.service_id = yaml['service_id']
end

TEST_NUMBER = yaml['test_number']

def the_message
  "Mblox gem test sent at #{Time.now}"
end

def result_ok
  "RequestResult: \"0:OK\" / SubscriberResult: \"0:OK\""
end

def result_unroutable
  "RequestResult: \"0:OK\" / SubscriberResult: \"10:MsipRejectCode=29 Number unroutable:2e Do not retry:2e\""
end
