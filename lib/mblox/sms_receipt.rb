require 'mblox/from_xml'

module Mblox
  class SmsReceipt
    attr_reader :batch_id, :subscriber_number, :timestamp, :msg_reference, :status, :reason
    def initialize(xml)
      data = Mblox.from_xml(xml).xpath '//NotificationService'
      raise MissingExpectedXmlContentError, "Xml should have contained a 'NotificationService' node, but was #{xml}" if data.blank?

      data = data.xpath '//NotificationList'
      raise MissingExpectedXmlContentError, "Xml should have contained a 'NotificationService' -> 'NotificationList' node, but was #{xml}" if data.blank?

      data = data.xpath '//Notification'
      raise MissingExpectedXmlContentError, "Xml should have contained a 'NotificationService' -> 'NotificationList' -> 'Notification' node, but was #{xml}" if data.blank?
      @batch_id = data.attribute('BatchID').value.to_i

      data = data.xpath '//Subscriber'
      raise MissingExpectedXmlContentError, "Xml should have contained a 'NotificationService' -> 'NotificationList' -> 'Notification' -> 'Subscriber' node, but was #{xml}" if data.blank?

      @subscriber_number = value_at(:SubscriberNumber, data)
      @subscriber_number = @subscriber_number[1..-1] if '1' == @subscriber_number[0]

      timestamp = value_at(:TimeStamp, data)
      unless timestamp.blank?
        @timestamp = begin
          Time.strptime("#{timestamp}+0000", '%Y%m%d%H%M%z')
        rescue ArgumentError
          nil
        end
      end

      @timestamp = @timestamp.to_datetime if @timestamp
      @msg_reference = value_at(:MsgReference, data)
      @status = value_at(:Status, data)
      reason = value_at(:Reason, data)
      @reason = reason.blank? ? nil : reason.to_i
    end
    private
      def value_at(path, data)
        data = data.xpath("//#{path}")
        (data.empty? || data.children.empty?) ? nil : data.first.child.content
      end
  end
end
