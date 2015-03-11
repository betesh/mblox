# encoding: UTF-8
require 'active_support/core_ext/hash'
require 'addressable/uri'
require 'builder'
require "net/https"
require 'mblox/sms_response'
require 'sms_validation'

module Mblox
  class Sms < SmsValidation::Sms
    class BatchIdOutOfRangeError < ::ArgumentError; end
    class InvalidSenderIdError < ::ArgumentError; end
    LEGAL_CHARACTERS = "~\`!\"#\$\%&'\(\)*+,-.\/:;<=>?@_£¤¥§¿i¡ÄÅÃÆÇÉÑÖØÜßâáäåãæçèéìíñòöøóùüú\n\r\t ©"
    ILLEGAL_CHARACTERS = /([^a-zA-Z0-9#{LEGAL_CHARACTERS}\\])/

    def initialize(phone, message, batch_id=nil)
      super(phone, message)
      illegal_characters = ILLEGAL_CHARACTERS.match(message).to_a
      raise InvalidMessageError, "Message cannot contain the following special characters: #{illegal_characters.uniq.join(', ')}" unless illegal_characters.size.zero?
      raise BatchIdOutOfRangeError, "batch_id must be in the range 1 to #{MAX_BATCH_ID}.  The batch_id specified (#{batch_id}) is out of range." if !batch_id.blank? && (MAX_BATCH_ID < batch_id.to_i)
      @batch_id = batch_id.to_i unless batch_id.blank?
    end

    def send_from(sender_id, service_id=nil)
      raise InvalidSenderIdError, "You can only send from a 5-digit shortcode" unless Mblox.is_a_five_digit_number?(sender_id)
      @sender_id = sender_id.to_i.to_s
      unless service_id.nil?
        raise InvalidSenderIdError, "You can only send using a 5-digit service ID.  Leave out the 2nd argument of send_from to use the globally configured '#{Mblox.config.service_id}'" unless Mblox.is_a_five_digit_number?(service_id)
        @service_id = service_id.to_i.to_s
      end
    end

    def send
      messages.collect { |message| commit build(message) }
    end
    private
      def commit(request_body)
        SmsValidation.log "Sending SMS to Mblox:\n#{request_body}"
        request = self.class.request
        request.body = request_body
        response = self.class.http.start{ |http| http.request(request) }.body
        SmsValidation.log "Mblox responds with:\n#{response}"
        SmsResponse.from_xml(response)
      end

      def build(message)
	builder = Builder::XmlMarkup.new
	builder.instruct!(:xml, :encoding => "ISO-8859-1")
	builder.NotificationRequest(:Version => "3.5") do |nr|
	  nr.NotificationHeader do |nh|
	    nh.PartnerName(Mblox.config.partner_name)
	    nh.PartnerPassword(Mblox.config.password)
	  end
	  nr.NotificationList(:BatchID => @batch_id || 1) do |nl|
	    nl.Notification(:SequenceNumber => 1, :MessageType => :SMS, :Format => :UTF8) do |n|
	      n.Message do |m|
                m.cdata!(message)
              end
	      n.Profile(Mblox.config.profile_id)
	      n.SenderID(@sender_id || Mblox.config.sender_id, :Type => :Shortcode)
	      n.Tariff(Mblox.config.tariff)
	      n.Subscriber do |s|
		s.SubscriberNumber(@phone)
	      end
	      n.ServiceId(@service_id || Mblox.config.service_id)
	    end
	  end
	end
      end

      class << self
        def url
          @url ||= URI.parse(URI.escape(Mblox.config.outbound_url))
        end
        def http
          @http ||= Net::HTTP.new(url.host, url.port)
        end
        def request
          return @request if @request
          @request = Net::HTTP::Post.new(url.request_uri)
          @request.content_type = 'text/xml'
          @request
        end
      end
  end
end
