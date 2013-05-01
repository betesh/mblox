require "mblox/configuration"
require "mblox/sms"
require "mblox/sms_error"
require "mblox/version"

module Mblox
  class << self
    def log *args
      self.config.logger.__send__(self.config.log_level, *args) if self.config.logger
    end
  end
end
