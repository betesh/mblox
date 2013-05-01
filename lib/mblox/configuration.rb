module Mblox
  class << self
    def config
      @config ||= Configuration.new
    end
  end

  def self.configure
    yield self.config
  end

  class Configuration
    attr_accessor :outbound_url, :profile_id, :sender_id, :password, :partner_name, :tariff, :service_id
  end
end
