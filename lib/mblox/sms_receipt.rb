require 'mblox/from_xml'

module Mblox
  class SmsReceipt
    attr_reader :batch_id, :subscriber_number, :timestamp, :msg_reference, :status, :reason
    def initialize(xml)
      data = Mblox.from_xml(xml)['NotificationService']
      raise MissingExpectedXmlContentError, "Xml should have contained a 'NotificationService' node, but was #{xml}" if data.blank?

      data = data['NotificationList']
      raise MissingExpectedXmlContentError, "Xml should have contained a 'NotificationService' -> 'NotificationList' node, but was #{xml}" if data.blank?

      data = data['Notification']
      raise MissingExpectedXmlContentError, "Xml should have contained a 'NotificationService' -> 'NotificationList' -> 'Notification' node, but was #{xml}" if data.blank?

      @batch_id = data['BatchID'].to_i

      data = data['Subscriber']
      raise MissingExpectedXmlContentError, "Xml should have contained a 'NotificationService' -> 'NotificationList' -> 'Notification' -> 'Subscriber' node, but was #{xml}" if data.blank?

      @subscriber_number = data['SubscriberNumber']
      @subscriber_number = @subscriber_number[1..-1] if '1' == @subscriber_number[0]

      unless data['TimeStamp'].blank?
        @timestamp = begin
          Time.strptime("#{data['TimeStamp']}+0000", '%Y%m%d%H%M%z')
        rescue ArgumentError
          nil
        end
      end

      @timestamp = @timestamp.to_datetime if @timestamp

      @msg_reference = data['MsgReference']
      @status = data['Status']
      @reason = data['Reason'].blank? ? nil : data['Reason'].to_i
    end
  end
end
