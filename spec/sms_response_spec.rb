require "spec_helper"

describe Mblox::SmsResponse do
  let(:args) { { :request => Mblox::SmsResponse::Result.new(9, "SomeRequest"), :result => Mblox::SmsResponse::Result.new(10, "SomeResult") , :subscriber_result => Mblox::SmsResponse::Result.new(11, "SomeSubscriberResult")  } }

  [:request, :result, :subscriber_result].each do |attr|
    describe attr do
      it "must be a Result" do
        expect{described_class.new(args.merge(:"#{attr}" => 123))}.to raise_error(Mblox::ValidationError, "#{attr} must be of type Mblox::SmsResponse::Result")
      end
    end
  end
  [:request, :result].each do |attr|
    describe attr do
      it "cannot be blank" do
        expect{described_class.new(args.merge(:"#{attr}" => nil))}.to raise_error(Mblox::ValidationError, "#{attr} cannot be blank")
      end
    end
  end

  describe :subscriber_result do
    it "cannot be blank if result is ok" do
      expect{described_class.new(args.merge(:subscriber_result => nil))}.to_not raise_error
    end

    it "can be blank if result is not ok" do
      expect{described_class.new(args.merge(:subscriber_result => nil, :result => Mblox::SmsResponse::Result.new(0,'Thumbs Up!')))}.to raise_error(Mblox::ValidationError, "subscriber_result cannot be blank")
    end
  end


  it "should raise an error if request, result and subscriber_result are missing" do
    expect{described_class.new({})}.to raise_error(Mblox::ValidationError, "The following fields cannot be blank: request, result")
  end
  it "should raise an error if request, result and subscriber_result are the wrong types" do
    expect{described_class.new(:request => 'A', :result => Time.now, :subscriber_result => 32)}.to raise_error(Mblox::ValidationError, "The following fields must be of type Mblox::SmsResponse::Result: request, result, subscriber_result")
  end
  it "should raise an error if an unrecognized attribute is present" do
    expect{described_class.new(args.merge(:extra_attribute => 'ABC'))}.to raise_error(::ArgumentError, 'Unrecognized attributes: {:extra_attribute=>"ABC"}')
  end
end
