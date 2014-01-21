require 'active_support/core_ext/hash/keys.rb'
require 'mblox/from_xml'

module Mblox
  class SmsReceipt
    ATTRIBUTES = [:batch_id, :subscriber_number, :msg_reference, :status, :timestamp, :reason, :operator]
    attr_reader *ATTRIBUTES

    def initialize args
      args = args.symbolize_keys
      ATTRIBUTES.each do |attr|
        __send__("#{attr}=", args[attr])
        args.delete(attr)
      end
      raise ::ArgumentError, "Unrecognized attributes: #{args.inspect}" unless args.empty?
      missing_fields = ATTRIBUTES.reject { |attr| [:timestamp, :reason, :operator].include?(attr) || __send__(attr) }
      if 1 == missing_fields.count
        raise ValidationError, "#{missing_fields.first} cannot be blank"
      elsif missing_fields.count > 1
        raise ValidationError, "The following fields cannot be blank: #{missing_fields.join(', ')}"
      end
      raise ValidationError, "batch_id must be a Fixnum" unless batch_id.is_a?(Fixnum)
      raise ValidationError, "reason must be a Fixnum" unless reason.nil? || reason.is_a?(Fixnum)
      raise ValidationError, "timestamp must be a DateTime" unless timestamp.nil? || timestamp.is_a?(DateTime)
    end
    private
      attr_writer *ATTRIBUTES

    class << self
      def from_xml(xml)
        args = {}
        data = Mblox.from_xml(xml).xpath '//NotificationService'
        raise MissingExpectedXmlContentError, "Xml should have contained a 'NotificationService' node, but was #{xml}" if data.blank?

        data = data.xpath '//NotificationList'
        raise MissingExpectedXmlContentError, "Xml should have contained a 'NotificationService' -> 'NotificationList' node, but was #{xml}" if data.blank?

        data = data.xpath '//Notification'
        raise MissingExpectedXmlContentError, "Xml should have contained a 'NotificationService' -> 'NotificationList' -> 'Notification' node, but was #{xml}" if data.blank?
        args[:batch_id]= data.attribute('BatchID').value.to_i

        data = data.xpath '//Subscriber'
        raise MissingExpectedXmlContentError, "Xml should have contained a 'NotificationService' -> 'NotificationList' -> 'Notification' -> 'Subscriber' node, but was #{xml}" if data.blank?

        args[:subscriber_number] = value_at(:SubscriberNumber, data)
        args[:subscriber_number] = args[:subscriber_number][1..-1] if '1' == args[:subscriber_number][0]

        timestamp = value_at(:TimeStamp, data)
        unless timestamp.blank?
          args[:timestamp] = begin
            Time.strptime("#{timestamp}+0000", '%Y%m%d%H%M%z')
          rescue ArgumentError
            nil
          end
        end

        args[:timestamp] = args[:timestamp].to_datetime if args[:timestamp]
        args[:msg_reference] = value_at(:MsgReference, data)
        args[:status] = value_at(:Status, data)
        reason = value_at(:Reason, data)
        args[:reason] = reason.blank? ? nil : reason.to_i
        data = data.xpath('//Tags').xpath('//Tag')
        unless data.empty?
          data.each do |d|
            args[:operator] = d.child.content.to_i if "Operator" == data.attribute('Name').content
            break if args[:operator]
          end
        end
        new(args)
      end
      private
        def value_at(path, data)
          data = data.xpath("//#{path}")
          (data.empty? || data.children.empty?) ? nil : data.first.child.content
        end
    end
  end
end
