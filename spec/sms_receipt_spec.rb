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
            s.Reason
          end
        end
      end
    end
    xml.target!
  end

  it "should access attributes for valid data" do
    target = described_class.new(valid)
    target.batch_id.should == batch_id
    target.subscriber_number.should == subscriber_number
    target.timestamp.should == DateTime.new(2013,10,7,17,36)
    target.msg_reference.should == msg_reference
    target.status.should == status
    target.reason.should == reason
  end

  it "should raise error when missing notification service node" do
    expect{described_class.new(missing_notification_service)}.to raise_error(Mblox::MissingExpectedXmlContentError, "Xml should have contained a 'NotificationService' node, but was #{missing_notification_service}")
  end

  it "should raise error when missing notification list node" do
    expect{described_class.new(missing_notification_list)}.to raise_error(Mblox::MissingExpectedXmlContentError, "Xml should have contained a 'NotificationService' -> 'NotificationList' node, but was #{missing_notification_list}")
  end

  it "should raise error when missing notification node" do
    expect{described_class.new(missing_notification)}.to raise_error(Mblox::MissingExpectedXmlContentError, "Xml should have contained a 'NotificationService' -> 'NotificationList' -> 'Notification' node, but was #{missing_notification}")
  end

  it "should raise error when missing subscriber node" do
    expect{described_class.new(missing_subscriber)}.to raise_error(Mblox::MissingExpectedXmlContentError, "Xml should have contained a 'NotificationService' -> 'NotificationList' -> 'Notification' -> 'Subscriber' node, but was #{missing_subscriber}")
  end

  describe "subscriber_number" do
    it "should not drop leading character unless it is '1'" do
      target = described_class.new(unexpected_nested_values)
      target.subscriber_number.should == "2#{subscriber_number}"
    end
  end

  describe "reason" do
    it "should leave reason blank if it is nil" do
      target = described_class.new(unexpected_nested_values)
      target.reason.should be_nil
    end
  end

  describe "timestamp" do
    it "should fail gracefully if it can't be converted into a DateTime" do
      target = described_class.new(unexpected_nested_values)
      target.timestamp.should be_nil
    end
  end
end
