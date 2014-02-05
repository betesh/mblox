# encoding: UTF-8
require 'active_support/core_ext/hash'
require 'addressable/uri'
require 'builder'
require "net/https"
require 'mblox/sms_response'

module Mblox
  class Sms
    class InvalidPhoneNumberError < ::ArgumentError; end
    class InvalidMessageError < ::ArgumentError; end
    class BatchIdOutOfRangeError < ::ArgumentError; end
    class InvalidSenderIdError < ::ArgumentError; end
    MAX_LENGTH = 160
    MAX_SECTION_LENGTH = MAX_LENGTH - "(MSG XXX/XXX): ".size
    LEGAL_CHARACTERS = "~\`!\"#\$\%&'\(\)*+,-.\/:;<=>?@_£¤¥§¿i¡ÄÅÆÇÉÑÖØÜßâáäåæèéìñòöøóùüú\n\r\tí "
    ILLEGAL_CHARACTERS = /([^a-zA-Z0-9#{LEGAL_CHARACTERS}\\])/

    attr_reader :phone, :message

    ON_MESSAGE_TOO_LONG_HANDLER = {
      :raise_error => Proc.new { raise InvalidMessageError, "Message cannot be longer than #{MAX_LENGTH} characters" },
      :truncate => Proc.new { |message| Mblox.log "Truncating message due to length.  Message was: \"#{message}\" but will now be \"#{message = message[0,MAX_LENGTH]}\""; [message] },
      :split => Proc.new { |message| split_message(message) }
    }

    def initialize(phone, message, batch_id=nil)
      phone = phone.to_s
      raise InvalidPhoneNumberError, "Phone number must be ten digits" unless /\A[0-9]{10}\z/.match(phone)
      raise InvalidPhoneNumberError, "Phone number cannot begin with 0 or 1" if ['0','1'].include?(phone[0].to_s)
      raise InvalidMessageError, "Message cannot be blank" if message.empty?
      illegal_characters = ILLEGAL_CHARACTERS.match(message).to_a
      raise InvalidMessageError, "Message cannot contain the following special characters: #{illegal_characters.uniq.join(', ')}" unless illegal_characters.size.zero?
      Mblox.log "WARNING: Some characters may be lost because the message must be broken into at least 1000 sections" if message.size > (999 * MAX_SECTION_LENGTH)
      @message = (message.size > MAX_LENGTH) ? ON_MESSAGE_TOO_LONG_HANDLER[Mblox.config.on_message_too_long].call(message) : [message.dup]
      @phone = "1#{phone}"
      raise BatchIdOutOfRangeError, "batch_id must be in the range 1 to #{MAX_BATCH_ID}.  The batch_id specified (#{batch_id}) is out of range." if !batch_id.blank? && (MAX_BATCH_ID < batch_id.to_i)
      @batch_id = batch_id.to_i unless batch_id.blank?
    end

    def send_from(_)
      raise InvalidSenderIdError, "You can only send from a 5-digit shortcode" unless Mblox.is_a_five_digit_number?(_)
      @sender_id = _.to_i.to_s
    end

    def send
      @message.collect { |message| commit build(message) }
    end
    private
      def commit(request_body)
        Mblox.log "Sending SMS to Mblox:\n#{request_body}"
        request = self.class.request
        request.body = request_body
        response = self.class.http.start{ |http| http.request(request) }.body
        Mblox.log "Mblox responds with:\n#{response}"
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
	      n.ServiceId(Mblox.config.service_id)
	    end
	  end
	end
      end

      def self.section_counter(size)
        size / MAX_SECTION_LENGTH + ((size % MAX_SECTION_LENGTH).zero? ? 0 : 1)
      end

      def self.split_message(message)
        sections = section_counter(message.size)
        Mblox.log "Splitting message into #{sections} messages due to length."
        split_message = []
        (sections - 1).times do |i|
          first_char = i * MAX_SECTION_LENGTH
          Mblox.log "Section ##{i + 1} of ##{sections} contains characters #{first_char + 1} thru #{first_char + MAX_SECTION_LENGTH} of #{message.size}"
          split_message << "(MSG #{i+1}/#{sections}): #{message[first_char, MAX_SECTION_LENGTH]}"
        end
        first_char = (sections-1)*MAX_SECTION_LENGTH
        Mblox.log "Section ##{sections} of ##{sections} contains characters #{first_char + 1} thru #{message.size} of #{message.size}"
        split_message << "(MSG #{sections}/#{sections}): #{message[first_char..-1]}"
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
