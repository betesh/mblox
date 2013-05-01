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
    attr_reader :logger, :log_level
    def initialize
      @logger = Rails.logger if defined?(::Rails)
      @log_level = :debug
    end

    def log_at level
      validate @logger, level
      @log_level = level
    end
    def logger= logger
      validate logger, @log_level
      @logger = logger
    end
    private
      def validate logger, level
	raise ArgumentError, "Mblox log level must be set to :fatal, :error, :warn, :info or :debug" if (logger && !logger.respond_to?(level))
      end
  end
end
