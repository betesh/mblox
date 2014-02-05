# encoding: UTF-8
require "spec_helper"

module Mblox
  class Sms
    def build_for_test(message)
      build(message)
    end
  end
end

describe Mblox::Sms do
  def the_message
    "Mblox gem test sent at #{Time.now}"
  end
  before(:all) do
    Mblox.reset_configuration
    set_configuration
  end
  describe "phone number" do
    it "should be 10 digits" do
      expect { Mblox::Sms.new("2"*9, the_message) }.to raise_error(Mblox::Sms::InvalidPhoneNumberError, "Phone number must be ten digits")
      expect { Mblox::Sms.new("2"*10, the_message) }.to_not raise_error
      expect { Mblox::Sms.new("2"*11, the_message) }.to raise_error(Mblox::Sms::InvalidPhoneNumberError, "Phone number must be ten digits")
    end

    it "should not start with 0 or 1" do
      expect { Mblox::Sms.new("1"+"2"*9, the_message) }.to raise_error(Mblox::Sms::InvalidPhoneNumberError, "Phone number cannot begin with 0 or 1")
      expect { Mblox::Sms.new("0"+"2"*9, the_message) }.to raise_error(Mblox::Sms::InvalidPhoneNumberError, "Phone number cannot begin with 0 or 1")
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
      expect { Mblox::Sms.new(LANDLINE, "") }.to raise_error(Mblox::Sms::InvalidMessageError, "Message cannot be blank")
    end

    it "can be 160 characters long" do
      expect { Mblox::Sms.new(LANDLINE, "A"*160) }.to_not raise_error
    end

    it "will be truncated when the message is longer than 160 characters if configured to do so" do
      message = "A"+"ABCDEFGHIJ"*16
      Mblox.config.on_message_too_long = :truncate
      expect { @mblox = Mblox::Sms.new(LANDLINE, message) }.to_not raise_error
      @mblox.message.should eq([message[0,160]])
    end

    it "cannot be longer than 160 characters if configured to raise error" do
      Mblox.config.on_message_too_long = :raise_error
      expect { Mblox::Sms.new(LANDLINE, "A"*161) }.to raise_error(Mblox::Sms::InvalidMessageError, "Message cannot be longer than 160 characters")
    end

    it "should be split into multiple messages when longer than 160 characters if configured to split and even split" do
      message = "ABCDEFGHIJ"*58
      Mblox.config.on_message_too_long = :split
      expect { @mblox = Mblox::Sms.new(LANDLINE, message) }.to_not raise_error
      @mblox.message.should eq(["(MSG 1/4): #{message[0,145]}", "(MSG 2/4): #{message[145,145]}", "(MSG 3/4): #{message[290,145]}", "(MSG 4/4): #{message[435,145]}"])
      response = @mblox.send
      response.count.should eq(4)
      response.each { |r| r.unroutable?.should be_true }
    end

    it "should be split into multiple messages when longer than 160 characters if configured to split and not even split" do
      message = "ABCDEFGHIJ"*32
      Mblox.config.on_message_too_long = :split
      expect { @mblox = Mblox::Sms.new(LANDLINE, message) }.to_not raise_error
      @mblox.message.should eq(["(MSG 1/3): #{message[0,145]}", "(MSG 2/3): #{message[145,145]}", "(MSG 3/3): #{message[290..-1]}"])
      response = @mblox.send
      response.count.should eq(3)
      response.each { |r| r.unroutable?.should be_true }
    end

    it "should be safe from changing when short" do
      msg = the_message
      mblox = Mblox::Sms.new(TEST_NUMBER,msg)
      msg[1..3] = ''
      mblox.message.should eq([the_message])
    end

    it "should be safe from changing when long when configured to split" do
      Mblox.config.on_message_too_long = :split
      msg = the_message * 10
      mblox = Mblox::Sms.new(TEST_NUMBER,msg)
      msg[1..3] = ''
      mblox.message[0][11, 20].should eq(the_message[0,20])
    end

    it "should be safe from changing when long when configured to truncate" do
      Mblox.config.on_message_too_long = :truncate
      msg = the_message * 10
      mblox = Mblox::Sms.new(TEST_NUMBER,msg)
      msg[1..3] = ''
      mblox.message[0][0, 20].should eq(the_message[0,20])
    end
  end

  describe "SMS messages" do
    def expect_ok_response(response)
      response.ok?.should be_true
      response.unroutable?.should be_false
    end

    it "should be sent when the phone number is a Fixnum" do
      response = Mblox::Sms.new(TEST_NUMBER.to_i,the_message).send
      response.size.should eq(1)
      expect_ok_response(response.first)
    end

    it "should be sent when the phone number is a String" do
      response = Mblox::Sms.new(TEST_NUMBER.to_s,the_message).send
      response.size.should eq(1)
      expect_ok_response(response.first)
    end

    it "should allow 160-character messages" do
      response = Mblox::Sms.new(TEST_NUMBER,"A"*160).send
      response.size.should eq(1)
      expect_ok_response(response.first)
    end

    it "should be unroutable when sent to a landline" do
      response = Mblox::Sms.new(LANDLINE,the_message).send
      response.size.should eq(1)
      response.first.unroutable?.should be_true, "#{response.first.inspect} should have been unroutable"
      response.first.ok?.should be_false
    end

    Mblox::Sms::LEGAL_CHARACTERS.each_char do |i|
      it "allows the special char #{i}, correctly escaping illegal XML characters where necessary" do
        response = Mblox::Sms.new(LANDLINE,"#{the_message}#{i}#{the_message}").send
        response.size.should eq(1)
        response.first.ok?.should be_false
        response.first.unroutable?.should be_true
      end
    end

    it "can send all the legal characters" do
      response = Mblox::Sms.new(TEST_NUMBER,Mblox::Sms::LEGAL_CHARACTERS).send
      response.size.should eq(1)
      response.first.ok?.should be_true
    end

    it "can send a backslash" do
      response = Mblox::Sms.new(TEST_NUMBER,'\\').send
      response.size.should eq(1)
      response.first.ok?.should be_true
    end
  end

  describe "batch_id" do
    it "can be specified" do
      batch_id = 12345
      sms = Mblox::Sms.new(LANDLINE,the_message, batch_id)
      content = Hash.from_xml(sms.build_for_test(the_message))
      content['NotificationRequest']['NotificationList']['BatchID'].should eq("#{batch_id}")
    end

    it "get converted to a Fixnum" do
      batch_id = 12345
      sms = Mblox::Sms.new(LANDLINE,the_message, "#{batch_id}ab")
      content = Hash.from_xml(sms.build_for_test(the_message))
      content['NotificationRequest']['NotificationList']['BatchID'].should eq("#{batch_id}")
    end

    it "defaults to 1" do
      sms = Mblox::Sms.new(LANDLINE,the_message)
      content = Hash.from_xml(sms.build_for_test(the_message))
      content['NotificationRequest']['NotificationList']['BatchID'].should eq('1')
    end

    it "can be 99999999" do
      expect{Mblox::Sms.new(LANDLINE,the_message, 99999999)}.to_not raise_error
    end

    it "cannot be 100000000" do
      expect{Mblox::Sms.new(LANDLINE,the_message, 100000000)}.to raise_error(Mblox::Sms::BatchIdOutOfRangeError, 'batch_id must be in the range 1 to 99999999.  The batch_id specified (100000000) is out of range.')
    end
  end

  describe "send from" do
    before(:each) do
      @sms = Mblox::Sms.new(TEST_NUMBER,'This message should come from shortcode 55555')
    end
    describe "sender_id" do
      def raise_invalid_sender_id_error
        raise_error(Mblox::Sms::InvalidSenderIdError, 'You can only send from a 5-digit shortcode')
      end
      it "cannot be a 4-digit number" do
        expect{@sms.send_from(1234)}.to raise_invalid_sender_id_error
      end
      it "cannot be a 6-digit number" do
        expect{@sms.send_from(123456)}.to raise_invalid_sender_id_error
      end
      it "cannot be a blank string" do
        expect{@sms.send_from('')}.to raise_invalid_sender_id_error
      end
      it "cannot be a float" do
        expect{@sms.send_from(12345.6)}.to raise_invalid_sender_id_error
      end
    end
    it "should send from the value" do
      expect{@sms.send_from(55555)}.to_not raise_error
      @sms.send.first.ok?.should be_true
    end
  end
end
