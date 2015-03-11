module Mblox
  class << self
    def config
      @config ||= Configuration.new
    end

    def configure
      yield config
    end
  end

  class Configuration
    attr_accessor :outbound_url, :profile_id, :sender_id, :password, :partner_name, :tariff, :service_id
    attr_reader :logger, :log_level, :on_message_too_long
  end
end
