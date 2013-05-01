require "spec_helper"

describe "configuration" do
  describe "on_message_too_long" do
    it "should default to :raise_error" do
      Mblox.reset_configuration
      expect(Mblox.config.on_message_too_long).to eq(:raise_error)
    end

    it "should allow the value :truncate" do
      expect { Mblox.config.on_message_too_long = :truncate }.to_not raise_error
    end

    it "should allow the value :raise_error" do
      expect { Mblox.config.on_message_too_long = :raise_error }.to_not raise_error
    end

    it "should not allow other values and should remain in a valid state" do
      expect { Mblox.config.on_message_too_long = :do_nothing }.to raise_error(ArgumentError, "Mblox.config.on_message_too_long must be either :truncate or :raise_error")
      expect(Mblox.config.on_message_too_long).to eq(:raise_error)
    end
  end
end
