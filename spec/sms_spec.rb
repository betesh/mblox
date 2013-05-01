require "spec_helper"

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
    expect(mblox.phone).to eq("1#{TEST_NUMBER}")
  end
end

describe "message" do
  it "cannot be blank" do
    expect { Mblox::Sms.new("2"*10, "") }.to raise_error(Mblox::SmsError, "Message cannot be blank")
  end

  it "should be safe from changing" do
    msg = the_message
    mblox = Mblox::Sms.new(TEST_NUMBER,msg)
    msg[1..3] = ''
    expect(mblox.message).to eq(the_message)
  end
end

describe "SMS messages" do
  it "should be sent when the phone number is a Fixnum" do
    expect(Mblox::Sms.new(TEST_NUMBER.to_i,the_message).send).to eq(result_ok)
  end

  it "should be sent when the phone number is a String" do
    expect(Mblox::Sms.new(TEST_NUMBER.to_s,the_message).send).to eq(result_ok)
  end

  it "should fail when sent to a landline" do
    expect(Mblox::Sms.new("6176354500",the_message).send).to eq(result_unroutable)
  end
end
