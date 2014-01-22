require 'active_model/callbacks'
require 'active_model/validator'
require 'active_model/naming'
require 'active_model/translation'
require 'active_model/validations'
require 'active_model/errors'

require 'mblox/from_xml'

module Mblox
  class SmsResponse
    class Result
      include ActiveModel::Validations
      validates_presence_of :text, :code, :message => "%{attribute} cannot be blank"
      validates_numericality_of :code, :only_integer => true, :allow_nil => true, :message => "%{attribute} must be an integer"

      attr_reader :code, :text
      def initialize(code, text)
        @code, @text = (code.to_i.to_s == code ? code.to_i : code), text
      end

      def self.from_xml(xml, xpath)
        code, text = xml.xpath("//#{xpath}Code"), xml.xpath("//#{xpath}Text")
        new(code.first.child.content, text.first.child.content)
      end

      def ok?
        0 == @code
      end

      def ==(rhs)
        code == rhs.code && text == rhs.text
      end

      UNROUTABLE_TEXT = "MsipRejectCode=29 Number unroutable:2e Do not retry:2e"
      UNROUTABLE = new(10, UNROUTABLE_TEXT)
    end


    ATTRIBUTES = [:request, :result, :subscriber_result]
    attr_reader *ATTRIBUTES

    def initialize args
      args = args.symbolize_keys
      ATTRIBUTES.each do |attr|
        __send__("#{attr}=", args[attr])
        args.delete(attr)
      end
      raise ::ArgumentError, "Unrecognized attributes: #{args.inspect}" unless args.empty?

      wrong_type_fields = ATTRIBUTES.reject { |attr| __send__(attr).nil? ||  __send__(attr).is_a?(self.class::Result) }
      if 1 == wrong_type_fields.count
        raise ValidationError, "#{wrong_type_fields.first} must be of type Mblox::SmsResponse::Result"
      elsif wrong_type_fields.count > 1
        raise ValidationError, "The following fields must be of type Mblox::SmsResponse::Result: #{wrong_type_fields.join(', ')}"
      end

      missing_fields = [:request, :result].reject { |attr| __send__(attr) }
      missing_fields << :subscriber_result if result && result.ok? && subscriber_result.nil?
      if 1 == missing_fields.count
        raise ValidationError, "#{missing_fields.first} cannot be blank"
      elsif missing_fields.count > 1
        raise ValidationError, "The following fields cannot be blank: #{missing_fields.join(', ')}"
      end
    end

    def ok?
      @request.ok? && @result.ok? && @subscriber_result.ok?
    end

    def unroutable?
      @request.ok? && @result.ok? && Result::UNROUTABLE == @subscriber_result
    end

    private
      attr_writer *ATTRIBUTES

    class << self
      def from_xml(xml)
        args = {}
        data = Mblox.from_xml(xml).xpath '//NotificationRequestResult'

        raise MissingExpectedXmlContentError, "Xml should have contained a 'NotificationRequestResult' node, but was #{xml}" if data.blank?
        header = data.xpath '//NotificationResultHeader'
        raise MissingExpectedXmlContentError, "Xml should have contained a 'NotificationRequestResult' -> 'NotificationResultHeader' node, but was #{xml}" if header.blank?
        args[:request] = Result.from_xml(header, :RequestResult)
        args[:request] = nil unless args[:request].valid?

        result_list = data.xpath '//NotificationResultList'
        raise MissingExpectedXmlContentError, "Xml should have contained a 'NotificationRequestResult' -> 'NotificationResultList' node, but was #{xml}" if result_list.blank?
        result_list = result_list.xpath '//NotificationResult'
        raise MissingExpectedXmlContentError, "Xml should have contained a 'NotificationRequestResult' -> 'NotificationResultList' -> 'NotificationResult' node, but was #{xml}" if result_list.blank?
        args[:result] = Result.from_xml(result_list, :NotificationResult)
        args[:result] = nil unless args[:result].valid?

        if args[:result].ok?
          result_list = result_list.xpath '//SubscriberResult'
          raise MissingExpectedXmlContentError, "Xml should have contained a 'NotificationRequestResult' -> 'NotificationResultList' -> 'NotificationResult' -> 'SubscriberResult' node, but was #{xml}" if result_list.blank?
          args[:subscriber_result] = Result.from_xml(result_list, :SubscriberResult)
          args[:subscriber_result] = nil unless args[:subscriber_result].valid?
        end
        new(args)
      end
    end
  end
end
