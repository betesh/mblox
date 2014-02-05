require "mblox/configuration"
require "mblox/sms"
require "mblox/sms_receipt"
require "mblox/version"

module Mblox
  MAX_BATCH_ID = (10**8)-1
  class << self
    def log *args
      self.config.logger.__send__(self.config.log_level, *args) if self.config.logger
    end
    def is_a_five_digit_number?(_)
      ((_.is_a?(Fixnum) || _.is_a?(String)) && 5 == _.to_i.to_s.size)
    end
  end
end
