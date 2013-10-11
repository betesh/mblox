require "mblox/configuration"
require "mblox/sms"
require "mblox/version"

module Mblox
  MAX_BATCH_ID = (10**8)-1
  class << self
    def log *args
      self.config.logger.__send__(self.config.log_level, *args) if self.config.logger
    end
  end
  class MissingExpectedXmlContentError < StandardError; end
end
