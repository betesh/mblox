require "spec_helper"

describe Mblox::Configuration do
  describe "logger" do
    before(:each) do
      Mblox.reset_configuration
    end

    after(:all) do
      set_configuration
    end

    [:fatal, :error, :warn, :info, :debug].each do |val|
      it "should allow log level ':#{val}'" do
        Mblox.config.log_at val
        Mblox.config.logger = ::Logger.new('/dev/null')
        expect { Mblox.log "Some info" }.to_not raise_error
      end
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
      expect(Mblox.config.log_level).to eq(:debug)
      expect { Mblox.log "Some news" }.to_not raise_error
    end
  end

  describe "on_message_too_long" do
    it "should default to :raise_error" do
      Mblox.reset_configuration
      expect(Mblox.config.on_message_too_long).to eq(:raise_error)
    end

    [:raise_error, :split, :truncate].each do |val|
      it "should allow the value ':#{val}'" do
        expect { Mblox.config.on_message_too_long = val }.to_not raise_error
        expect(Mblox.config.on_message_too_long).to eq(val)
      end
    end

    it "should not allow other values and should remain in a valid state" do
      original = Mblox.config.on_message_too_long
      expect { Mblox.config.on_message_too_long = :do_nothing }.to raise_error(ArgumentError, "Mblox.config.on_message_too_long must be either :truncate, :split or :raise_error")
      expect(Mblox.config.on_message_too_long).to eq(original)
    end
  end
end
