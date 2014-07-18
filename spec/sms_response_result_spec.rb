require "spec_helper"

describe Mblox::SmsResponse::Result do
  describe "code" do
    it "cannot be blank" do
      result = described_class.new(nil, "123")
      result.valid?
      expect(result.errors[:code]).to include("Code cannot be blank")
    end

    it "must be a number" do
      result = described_class.new('abc', "123")
      result.valid?
      expect(result.errors[:code]).to include("Code must be an integer")
    end

    it "must be an integer" do
      result = described_class.new(3.14159, "123")
      result.valid?
      expect(result.errors[:code]).to include("Code must be an integer")
    end
  end

  describe "text" do
    it "cannot be blank" do
      result = described_class.new(0, '')
      result.valid?
      expect(result.errors[:text]).to include("Text cannot be blank")
    end
  end

  describe "ok?" do
    it "is true for code 0" do
      expect(described_class.new(0, "123")).to be_ok
    end

    10.times do |i|
      it "is false for code #{i+1}" do
        expect(described_class.new(i+1, "123")).not_to be_ok
      end
    end
  end

  describe "==" do
    it "should be true if code and text are the same" do
      lhs = described_class.new(0, 'OK')
      rhs = described_class.new(0, 'OK')
      expect(lhs).to eq(rhs)
    end

    it "should be false if code does not match" do
      lhs = described_class.new(0, 'OK')
      rhs = described_class.new(4, 'OK')
      expect(lhs).not_to eq(rhs)
    end
    it "should be false if text does not match" do
      lhs = described_class.new(0, 'OK')
      rhs = described_class.new(0, '__OK__')
      expect(lhs).not_to eq(rhs)
    end
  end
end
