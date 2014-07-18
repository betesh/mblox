require "spec_helper"

describe Mblox::SmsReceipt do
  def msg_reference
    'VIShbJoUqEcRLNDWosxwYOLP'
  end

  def batch_id
    1234
  end

  def subscriber_number
    '8885554444'
  end

  def status
    'acked'
  end

  def reason
    3
  end

  describe "from_xml" do
  def valid
    xml = Builder::XmlMarkup.new
    xml.instruct!(:xml, :version => 1.0, :encoding => "ISO-8859-1", :standalone => :yes)
    xml.NotificationService(:Version => "2.3") do |ns|
      ns.NotificationList do |nl|
        nl.Notification(:BatchID => batch_id) do |n|
          n.Subscriber do |s|
            s.SubscriberNumber("1#{subscriber_number}")
            s.TimeStamp(201310071736)
            s.MsgReference(msg_reference)
            s.Status(status)
            s.Reason(reason)
            s.Tags do |t|
              t.Tag(10487, :Name => :Operator)
            end
          end
        end
      end
    end
    xml.target!
  end

  def missing_notification_service
    xml = Builder::XmlMarkup.new
    xml.instruct!(:xml, :version => 1.0, :encoding => "ISO-8859-1", :standalone => :yes)
    xml.WrongNode(:Version => "2.3") do |ns|
    end
    xml.target!
  end

  def missing_notification_list
    xml = Builder::XmlMarkup.new
    xml.instruct!(:xml, :version => 1.0, :encoding => "ISO-8859-1", :standalone => :yes)
    xml.NotificationService(:Version => "2.3") do |ns|
    end
    xml.target!
  end

  def missing_notification
    xml = Builder::XmlMarkup.new
    xml.instruct!(:xml, :version => 1.0, :encoding => "ISO-8859-1", :standalone => :yes)
    xml.NotificationService(:Version => "2.3") do |ns|
      ns.NotificationList do |nl|
        nl.WrongNode do |n|
        end
      end
    end
    xml.target!
  end

    def missing_subscriber
    xml = Builder::XmlMarkup.new
    xml.instruct!(:xml, :version => 1.0, :encoding => "ISO-8859-1", :standalone => :yes)
    xml.NotificationService(:Version => "2.3") do |ns|
      ns.NotificationList do |nl|
        nl.Notification(:BatchID => batch_id) do |n|
        end
      end
    end
    xml.target!
  end

  def unexpected_nested_values
    xml = Builder::XmlMarkup.new
    xml.instruct!(:xml, :version => 1.0, :encoding => "ISO-8859-1", :standalone => :yes)
    xml.NotificationService(:Version => "2.3") do |ns|
      ns.NotificationList do |nl|
        nl.Notification(:BatchID => batch_id) do |n|
          n.Subscriber do |s|
            s.SubscriberNumber("2#{subscriber_number}")
            s.TimeStamp('Abcdefg')
            s.MsgReference(msg_reference)
            s.Status(status)
            s.Reason
          end
        end
      end
    end
    xml.target!
  end

  it "should access attributes for valid data" do
    target = described_class.from_xml(valid)
    expect(target.batch_id).to eq(batch_id)
    expect(target.subscriber_number).to eq(subscriber_number)
    expect(target.timestamp).to eq(DateTime.new(2013,10,7,17,36))
    expect(target.msg_reference).to eq(msg_reference)
    expect(target.status).to eq(status)
    expect(target.reason).to eq(reason)
    expect(target.operator).to eq(10487)
  end

  it "should raise error when missing root node" do
    expect{described_class.from_xml('Abcdefg')}.to raise_error(Mblox::MissingExpectedXmlContentError, "'Abcdefg' is not parseable as XML")
  end

  it "should raise error when missing notification service node" do
    expect{described_class.from_xml(missing_notification_service)}.to raise_error(Mblox::MissingExpectedXmlContentError, "Xml should have contained a 'NotificationService' node, but was #{missing_notification_service}")
  end

  it "should raise error when missing notification list node" do
    expect{described_class.from_xml(missing_notification_list)}.to raise_error(Mblox::MissingExpectedXmlContentError, "Xml should have contained a 'NotificationService' -> 'NotificationList' node, but was #{missing_notification_list}")
  end

  it "should raise error when missing notification node" do
    expect{described_class.from_xml(missing_notification)}.to raise_error(Mblox::MissingExpectedXmlContentError, "Xml should have contained a 'NotificationService' -> 'NotificationList' -> 'Notification' node, but was #{missing_notification}")
  end

  it "should raise error when missing subscriber node" do
    expect{described_class.from_xml(missing_subscriber)}.to raise_error(Mblox::MissingExpectedXmlContentError, "Xml should have contained a 'NotificationService' -> 'NotificationList' -> 'Notification' -> 'Subscriber' node, but was #{missing_subscriber}")
  end

  describe "subscriber_number" do
    it "should not drop leading character unless it is '1'" do
      target = described_class.from_xml(unexpected_nested_values)
      expect(target.subscriber_number).to eq("2#{subscriber_number}")
    end
  end

  describe "reason" do
    it "should leave reason blank if it is nil" do
      target = described_class.from_xml(unexpected_nested_values)
      expect(target.reason).to be_nil
    end
  end

  describe "timestamp" do
    it "should fail gracefully if it can't be converted into a DateTime" do
      target = described_class.from_xml(unexpected_nested_values)
      expect(target.timestamp).to be_nil
    end
  end
  end

  describe "initialize" do
    let(:args) { { :batch_id => batch_id, :subscriber_number => subscriber_number, :msg_reference => msg_reference, :status => status, :timestamp => DateTime.new(2013,10,7,17,36), :reason => reason, :operator => 10487 } }

    [:batch_id, :subscriber_number, :msg_reference, :status].each do |attr|
      it "should raise an error if #{attr} is missing" do
        expect{described_class.new(args.merge(attr => nil))}.to raise_error(Mblox::ValidationError, "#{attr} cannot be blank")
      end
    end

    [:timestamp, :reason, :operator].each do |attr|
      it "should not raise an error if #{attr} is missing" do
        expect{described_class.new(args.merge(attr => nil))}.to_not raise_error
      end
    end

    it "should raise an error if batch_id, subscriber_number, msg_reference and status are missing" do
      expect{described_class.new(args.merge(:batch_id => nil, :subscriber_number => nil, :msg_reference => nil, :status => nil))}.to raise_error(Mblox::ValidationError, "The following fields cannot be blank: batch_id, subscriber_number, msg_reference, status")
    end

    it "should raise an error if batch_id is not a Fixnum" do
      expect{described_class.new(args.merge(:batch_id => 'ABC'))}.to raise_error(Mblox::ValidationError, "batch_id must be a Fixnum")
    end

    it "should raise an error if reason is not a Fixnum" do
      expect{described_class.new(args.merge(:reason => 'ABC'))}.to raise_error(Mblox::ValidationError, "reason must be a Fixnum")
    end

    it "should raise an error if timestamp is not a DateTime" do
      expect{described_class.new(args.merge(:timestamp => Time.now))}.to raise_error(Mblox::ValidationError, "timestamp must be a DateTime")
    end

    it "should raise an error if an unrecognized attribute is present" do
      expect{described_class.new(args.merge(:extra_attribute => 'ABC'))}.to raise_error(::ArgumentError, 'Unrecognized attributes: {:extra_attribute=>"ABC"}')
    end
  end
end
