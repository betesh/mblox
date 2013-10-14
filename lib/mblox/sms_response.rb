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

      def ok?
        0 == @code
      end

      def ==(rhs)
        code == rhs.code && text == rhs.text
      end

      UNROUTABLE_TEXT = "MsipRejectCode=29 Number unroutable:2e Do not retry:2e"
      UNROUTABLE = new(10, UNROUTABLE_TEXT)
    end

    attr_reader :request, :result, :subscriber_result
    def initialize(xml)
      data = Mblox.from_xml(xml)['NotificationRequestResult']

      raise MissingExpectedXmlContentError, "Xml should have contained a 'NotificationRequestResult' node, but was #{xml}" if data.blank?
      header = data['NotificationResultHeader']
      raise MissingExpectedXmlContentError, "Xml should have contained a 'NotificationRequestResult' -> 'NotificationResultHeader' node, but was #{xml}" if header.blank?
      @request = Result.new(header['RequestResultCode'], header['RequestResultText'])
      @request = nil unless @request.valid?

      result_list = data['NotificationResultList']
      raise MissingExpectedXmlContentError, "Xml should have contained a 'NotificationRequestResult' -> 'NotificationResultList' node, but was #{xml}" if result_list.blank?
      result_list = result_list['NotificationResult']
      raise MissingExpectedXmlContentError, "Xml should have contained a 'NotificationRequestResult' -> 'NotificationResultList' -> 'NotificationResult' node, but was #{xml}" if result_list.blank?
      @result = Result.new(result_list['NotificationResultCode'], result_list['NotificationResultText'])
      @result = nil unless @result.valid?

      if @result.ok?
        result_list = result_list['SubscriberResult']
        raise MissingExpectedXmlContentError, "Xml should have contained a 'NotificationRequestResult' -> 'NotificationResultList' -> 'NotificationResult' -> 'SubscriberResult' node, but was #{xml}" if result_list.blank?
        @subscriber_result = Result.new(result_list['SubscriberResultCode'], result_list['SubscriberResultText'])
        @subscriber_result = nil unless @subscriber_result.valid?
      end
    end

    def ok?
      @request.ok? && @result.ok? && @subscriber_result.ok?
    end

    def unroutable?
      @request.ok? && @result.ok? && Result::UNROUTABLE == @subscriber_result
    end
  end
end
