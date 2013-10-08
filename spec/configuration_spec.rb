require "spec_helper"

describe Mblox::Configuration do
  describe "logger" do
    before(:each) do
      Mblox.reset_configuration
    end

    after(:all) do
      set_configuration
    end

    it "should allow log level info" do
      Mblox.config.log_at :info
      Mblox.config.logger = ::Logger.new('/dev/null')
      expect { Mblox.log "Some info" }.to_not raise_error
    end

    it "should default to log level debug" do
      expect(Mblox.config.log_level).to eq(:debug)
      expect { Mblox.log "Some debug info" }.to_not raise_error
    end

    it "should not allow log level news when the logger is created after log level is set" do
      Mblox.config.log_at :news
      expect { Mblox.config.logger = ::Logger.new(STDOUT)}.to raise_error(ArgumentError, "Mblox log level must be set to :fatal, :error, :warn, :info or :debug")
      expect { Mblox.log "Some news" }.to_not raise_error
    end

    it "should not allow log level news when the logger is created before log level is set and should remain in a valid state" do
      Mblox.config.logger = ::Logger.new("/dev/null")
      expect { Mblox.config.log_at :news }.to raise_error(ArgumentError, "Mblox log level must be set to :fatal, :error, :warn, :info or :debug")
      expect { Mblox.log "Some news" }.to_not raise_error
    end
  end

  describe "on_message_too_long" do
    it "should default to :raise_error" do
      Mblox.reset_configuration
      expect(Mblox.config.on_message_too_long).to eq(:raise_error)
    end

    it "should allow the value :truncate" do
      expect { Mblox.config.on_message_too_long = :truncate }.to_not raise_error
    end

    it "should allow the value :split" do
      expect { Mblox.config.on_message_too_long = :split }.to_not raise_error
    end

    it "should allow the value :raise_error" do
      expect { Mblox.config.on_message_too_long = :raise_error }.to_not raise_error
    end

    it "should not allow other values and should remain in a valid state" do
      expect { Mblox.config.on_message_too_long = :do_nothing }.to raise_error(ArgumentError, "Mblox.config.on_message_too_long must be either :truncate, :split or :raise_error")
      expect(Mblox.config.on_message_too_long).to eq(:raise_error)
    end
  end
end
