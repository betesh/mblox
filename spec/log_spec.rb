require "spec_helper"
require "logger"

module Mblox
  class << self
    def reset_configuration
      @config = Configuration.new
    end
  end
end

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
