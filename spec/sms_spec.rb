require "spec_helper"

describe Mblox::Sms do
  before(:all) do
    set_configuration
  end
  describe "phone number" do
    it "should be 10 digits" do
      expect { Mblox::Sms.new("2"*9, the_message) }.to raise_error(Mblox::SmsError, "Phone number must be ten digits")
      expect { Mblox::Sms.new("2"*10, the_message) }.to_not raise_error
      expect { Mblox::Sms.new("2"*11, the_message) }.to raise_error(Mblox::SmsError, "Phone number must be ten digits")
    end

    it "should not start with 0 or 1" do
      expect { Mblox::Sms.new("1"+"2"*9, the_message) }.to raise_error(Mblox::SmsError, "Phone number cannot begin with 0 or 1")
      expect { Mblox::Sms.new("0"+"2"*9, the_message) }.to raise_error(Mblox::SmsError, "Phone number cannot begin with 0 or 1")
    end

    it "should be safe from changing" do
      number = TEST_NUMBER.to_s
      mblox = Mblox::Sms.new(number,the_message)
      number[1..3] = ''
      mblox.phone.should eq("1#{TEST_NUMBER}")
    end
  end

  describe "message" do
    it "cannot be blank" do
      expect { Mblox::Sms.new("2"*10, "") }.to raise_error(Mblox::SmsError, "Message cannot be blank")
    end

    it "can be 160 characters long" do
      expect { Mblox::Sms.new("2"*10, "A"*160) }.to_not raise_error
    end

    it "will be truncated when the message is longer than 160 characters if configured to do so" do
      message = "A"+"ABCDEFGHIJ"*16
      Mblox.config.on_message_too_long = :truncate
      expect { @mblox = Mblox::Sms.new("2"*10, message) }.to_not raise_error
      @mblox.message.should eq([message[0,160]])
    end

    it "cannot be longer than 160 characters if configured to raise error" do
      Mblox.config.on_message_too_long = :raise_error
      expect { Mblox::Sms.new("2"*10, "A"*161) }.to raise_error(Mblox::SmsError, "Message cannot be longer than 160 characters")
    end

    it "should be split into multiple messages when longer than 160 characters if configured to split and even split" do
      message = "ABCDEFGHIJ"*58
      Mblox.config.on_message_too_long = :split
      expect { @mblox = Mblox::Sms.new("2"*10, message) }.to_not raise_error
      @mblox.message.should eq(["(MSG 1/4): #{message[0,145]}", "(MSG 2/4): #{message[145,145]}", "(MSG 3/4): #{message[290,145]}", "(MSG 4/4): #{message[435,145]}"])
      @mblox.send.should eq(Array.new(4, result_unroutable))
    end

    it "should be split into multiple messages when longer than 160 characters if configured to split and not even split" do
      message = "ABCDEFGHIJ"*32
      Mblox.config.on_message_too_long = :split
      expect { @mblox = Mblox::Sms.new("2"*10, message) }.to_not raise_error
      @mblox.message.should eq(["(MSG 1/3): #{message[0,145]}", "(MSG 2/3): #{message[145,145]}", "(MSG 3/3): #{message[290..-1]}"])
      @mblox.send.should eq(Array.new(3, result_unroutable))
    end

    it "should be safe from changing when short" do
      msg = the_message
      mblox = Mblox::Sms.new(TEST_NUMBER,msg)
      msg[1..3] = ''
      mblox.message.should eq([the_message])
    end

    it "should be safe from changing when long" do
      msg = the_message * 10
      mblox = Mblox::Sms.new(TEST_NUMBER,msg)
      msg[1..3] = ''
      mblox.message[0][11, 20].should eq(the_message[0,20])
    end
  end

  describe "SMS messages" do
    it "should be sent when the phone number is a Fixnum" do
      Mblox::Sms.new(TEST_NUMBER.to_i,the_message).send.should eq([result_ok])
    end

    it "should be sent when the phone number is a String" do
      Mblox::Sms.new(TEST_NUMBER.to_s,the_message).send.should eq([result_ok])
    end

    it "should allow 160-character messages" do
      Mblox::Sms.new(TEST_NUMBER,"A"*160).send.should eq([result_ok])
    end

    it "should fail when sent to a landline" do
      Mblox::Sms.new("6176354500",the_message).send.should eq([result_unroutable])
    end
  end
end
