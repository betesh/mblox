require "spec_helper"

describe Mblox::SmsResponse::Result do
  describe "code" do
    it "cannot be blank" do
      result = described_class.new(nil, "123")
      result.valid?
      result.errors[:code].should include("Code cannot be blank")
    end

    it "must be a number" do
      result = described_class.new('abc', "123")
      result.valid?
      result.errors[:code].should include("Code must be an integer")
    end

    it "must be an integer" do
      result = described_class.new(3.14159, "123")
      result.valid?
      result.errors[:code].should include("Code must be an integer")
    end
  end

  describe "text" do
    it "cannot be blank" do
      result = described_class.new(0, '')
      result.valid?
      result.errors[:text].should include("Text cannot be blank")
    end
  end

  describe "ok?" do
    it "is true for code 0" do
      described_class.new(0, "123").ok?.should be_true
    end

    10.times do |i|
      it "is false for code #{i+1}" do
        described_class.new(i+1, "123").ok?.should be_false
      end
    end
  end

  describe "==" do
    it "should be true if code and text are the same" do
      lhs = described_class.new(0, 'OK')
      rhs = described_class.new(0, 'OK')
      (lhs == rhs).should be_true
    end

    it "should be false if code does not match" do
      lhs = described_class.new(0, 'OK')
      rhs = described_class.new(4, 'OK')
      (lhs == rhs).should be_false
    end
    it "should be false if text does not match" do
      lhs = described_class.new(0, 'OK')
      rhs = described_class.new(0, '__OK__')
      (lhs == rhs).should be_false
    end
  end
end
