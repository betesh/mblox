# encoding: UTF-8
require "spec_helper"

describe Mblox::Sms do
  TEN_CHARACTERS = "ABCDEFGHIJ"
  ONE_HUNDRED_SIXTY_CHARACTERS = TEN_CHARACTERS * 16
  let(:phone_number) { TEST_NUMBER }
  let(:message) { "Mblox gem test sent at #{Time.now}" }

  subject { described_class.new(phone_number, message) }

  before(:all) do
    Mblox.reset_configuration
    set_configuration
  end

  describe "phone number" do
    describe "when 9 digits" do
      let(:phone_number) { '2' * 9 }

      it "should raise an error" do
        expect {subject}.to raise_error(Mblox::Sms::InvalidPhoneNumberError, "Phone number must be ten digits")
      end
    end

    describe "when 11 digits" do
      let(:phone_number) { '2' * 11 }

      it "should raise an error" do
        expect {subject}.to raise_error(Mblox::Sms::InvalidPhoneNumberError, "Phone number must be ten digits")
      end
    end

    describe "when 10 digits" do
      let(:phone_number) { '2' * 10 }

      it "should not raise an error" do
        expect {subject}.not_to raise_error
      end
    end

    describe "when it starts with a 0" do
      let(:phone_number) { '0' + '2' * 9 }

      it "should raise an error" do
        expect {subject}.to raise_error(Mblox::Sms::InvalidPhoneNumberError, "Phone number cannot begin with a \"0\"")
      end
    end

    describe "when it starts with a 1" do
      let(:phone_number) { '1' + '2' * 9 }

      it "should raise an error" do
        expect {subject}.to raise_error(Mblox::Sms::InvalidPhoneNumberError, "Phone number cannot begin with a \"1\"")
      end
    end

    describe "when phone_number changes after instantiation" do
      let(:phone_number) { super().to_s }
      it "should be safe from changing" do
        expect{phone_number[1..3] = ''}.not_to change{subject.phone}
      end
    end
  end

  describe "message" do
    let(:on_message_too_long) { :raise_error }

    before(:each) do
      SmsValidation.configuration.on_message_too_long = on_message_too_long
    end

    describe "when message is blank" do
      let(:message) { "" }

      it "should raise an error" do
        expect{subject}.to raise_error(Mblox::Sms::InvalidMessageError, "Message cannot be blank")
      end
    end

    describe "when 160 characters long" do
      let(:message) { ONE_HUNDRED_SIXTY_CHARACTERS }

      it "sohuld not raise an error" do
        expect{subject}.to_not raise_error
      end
    end

    describe "when message is longer than 160 characters" do
      let(:message) { "A" + ONE_HUNDRED_SIXTY_CHARACTERS }

      describe "when on_message_too_long = :truncate" do
        let(:on_message_too_long) { :truncate }

        it "will be truncated when the message is longer than 160 characters" do
          expect(subject.message).to eq(message[0,160])
        end

        it "should be safe from changing when long" do
          expect{message[1..3] = ''}.not_to change{subject.message}
        end
      end

      describe "when on_message_too_long = :raise_error" do
        let(:on_message_too_long) { :raise_error }

        it "cannot be longer than 160 characters" do
          expect{subject}.to raise_error(Mblox::Sms::MessageTooLongError, "Message cannot be longer than 160 characters")
        end
      end

      describe "when on_message_too_long = :split" do
        let(:on_message_too_long) { :split }
        let(:phone_number) { LANDLINE }

        describe "when split is even" do
          let(:message) { TEN_CHARACTERS * 58 }

          it "should be split into multiple messages when longer than 160 characters" do
            expect(subject.messages).to eq(["(MSG 1/4): #{message[0,145]}", "(MSG 2/4): #{message[145,145]}", "(MSG 3/4): #{message[290,145]}", "(MSG 4/4): #{message[435,145]}"])
            response = subject.send
            expect(response.count).to eq(4)
            response.each { |r| expect(r).to be_unroutable }
          end
        end

        describe "when split is not even" do
          let(:message) { TEN_CHARACTERS * 32 }

          it "should be split into multiple messages when longer than 160 characters" do
            expect(subject.messages).to eq(["(MSG 1/3): #{message[0,145]}", "(MSG 2/3): #{message[145,145]}", "(MSG 3/3): #{message[290..-1]}"])
            response = subject.send
            expect(response.count).to eq(3)
            response.each { |r| expect(r).to be_unroutable }
          end

          it "should be safe from changing when long" do
            expect{message[1..3] = ''}.not_to change{subject.messages}
          end
        end
      end
    end

    it "should be safe from changing when long" do
      expect{message[1..3] = ''}.not_to change{subject.message}
    end
  end

  describe "SMS messages" do
    let(:response) { subject.send }

    def should_have_ok_response
      expect(response.size).to eq(1)
      expect(response[0]).to be_ok
      expect(response[0]).not_to be_unroutable
    end

    def should_have_unroutable_response
      expect(response.size).to eq(1)
      expect(response[0]).not_to be_ok
      expect(response[0]).to be_unroutable
    end

    it { should_have_ok_response }

    describe "when phone_number is a String" do
      let(:phone_number) { super().to_s }

      it { should_have_ok_response }
    end

    describe "when message is 160 characters" do
      let(:message) { ONE_HUNDRED_SIXTY_CHARACTERS }

      it { should_have_ok_response }
    end

    describe "when sent to a landline" do
      let(:phone_number) { LANDLINE }

      it { should_have_unroutable_response }
    end

    describe "when all legal characters are in message" do
      let(:message) { "#{described_class::LEGAL_CHARACTERS}\\" }
      it { should_have_ok_response }
    end
  end

  describe "batch_id" do
    let(:phone_number) { LANDLINE }

    subject { described_class.new(phone_number, message, batch_id) }

    def should_set_the_batch_id_to(expected)
      expect(subject).to receive(:commit) do |arg|
        expect(arg).to match(/<NotificationList BatchID=\"#{expected}\">/)
      end
      subject.send
    end

    describe "when a Fixnum" do
      let(:batch_id) { 12345 }

      it { should_set_the_batch_id_to(batch_id) }
    end

    describe "when a String" do
      let(:batch_id) { 12345.to_s }

      it { should_set_the_batch_id_to(batch_id) }
    end

    describe "when a Float" do
      let(:batch_id) { 12345.0 }

      it { should_set_the_batch_id_to(batch_id.to_i) }
    end

    describe "when default" do
      subject { described_class.new(phone_number, message) }

      it { should_set_the_batch_id_to(1) }
    end

    describe "when the maximum allowed" do
      let(:batch_id) { 99999999 }

      it { should_set_the_batch_id_to(batch_id) }
    end

    describe "when 1 more than the maximum allowed" do
      let(:batch_id) { 100000000 }

      it "should raise an error" do
        expect{subject}.to raise_error(Mblox::Sms::BatchIdOutOfRangeError, 'batch_id must be in the range 1 to 99999999.  The batch_id specified (100000000) is out of range.')
      end
    end
  end

  describe "send from" do
    let(:message) { "This message should come from shortcode 55555" }

    describe "sender_id" do
      def raise_invalid_sender_id_error
        raise_error(Mblox::Sms::InvalidSenderIdError, 'You can only send from a 5-digit shortcode')
      end

      it "cannot be a 4-digit number" do
        expect{subject .send_from(1234)}.to raise_invalid_sender_id_error
      end
      it "cannot be a 6-digit number" do
        expect{subject .send_from(123456)}.to raise_invalid_sender_id_error
      end
      it "cannot be a blank string" do
        expect{subject .send_from('')}.to raise_invalid_sender_id_error
      end
      it "cannot be a float" do
        expect{subject .send_from(12345.6)}.to raise_invalid_sender_id_error
      end
      it "cannot be nil" do
        expect{subject .send_from(nil)}.to raise_invalid_sender_id_error
      end
    end

    describe "service_id" do
      let(:sender_id) { Mblox.config.sender_id }

      def raise_invalid_service_id
        raise_error(Mblox::Sms::InvalidSenderIdError, "You can only send using a 5-digit service ID.  Leave out the 2nd argument of send_from to use the globally configured '#{Mblox.config.service_id}'")
      end

      it "cannot be a 4-digit number" do
        expect{subject.send_from(sender_id, 1234)}.to raise_invalid_service_id
      end
      it "cannot be a 6-digit number" do
        expect{subject.send_from(sender_id, 123456)}.to raise_invalid_service_id
      end
      it "cannot be a blank string" do
        expect{subject.send_from(sender_id, '')}.to raise_invalid_service_id
      end
      it "cannot be a float" do
        expect{subject.send_from(sender_id, 12345.6)}.to raise_invalid_service_id
      end
      it "can be nil" do
        expect{subject.send_from(sender_id, nil)}.to_not raise_error
      end
    end

    it "should send from the specified sender_id" do
      subject.send_from(55555)
      expect(subject).to receive(:commit) do |arg|
        expect(arg).to match(/<SenderID Type=\"Shortcode\">55555<\/SenderID>/)
      end
      subject.send
    end

    it "should send from the specified sender_id and service_id" do
      subject.send_from(55555, 44444)
      expect(subject).to receive(:commit) do |arg|
        expect(arg).to match(/<ServiceId>44444<\/ServiceId>/)
        expect(arg).to match(/<SenderID Type=\"Shortcode\">55555<\/SenderID>/)
      end
      subject.send
    end
  end
end
