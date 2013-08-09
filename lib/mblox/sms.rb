require 'active_support/core_ext/hash'
require 'addressable/uri'
require 'builder'
require "net/https"

module Mblox
  class Sms
    MAX_LENGTH = 160
    MAX_SECTION_LENGTH = MAX_LENGTH - "(MSG X/X): ".size

    attr_reader :phone, :message

    ON_MESSAGE_TOO_LONG_HANDLER = {
      :raise_error => Proc.new { raise SmsError, "Message cannot be longer than #{MAX_LENGTH} characters" },
      :truncate => Proc.new { |message| Mblox.log "Truncating message due to length.  Message was: \"#{message}\" but will now be \"#{message = message[0,MAX_LENGTH]}\""; [message] },
      :split => Proc.new { |message| split_message(message) }
    }

    def initialize(phone,message)
      phone = phone.to_s
      raise SmsError, "Phone number must be ten digits" unless /\A[0-9]{10}\z/.match(phone)
      raise SmsError, "Phone number cannot begin with 0 or 1" if ['0','1'].include?(phone[0].to_s)
      raise SmsError, "Message cannot be blank" if message.empty?
      @message = (message.size > MAX_LENGTH) ? ON_MESSAGE_TOO_LONG_HANDLER[Mblox.config.on_message_too_long].call(message) : [message.dup]
      @phone = "1#{phone}"
    end

    def send
      @message.collect { |message| commit build(message) }
    end
    private
      def commit(request_body)
	Mblox.log "Sending SMS to Mblox:\n#{request_body}"
	uri = URI.parse(Mblox.config.outbound_url)
	http = Net::HTTP.new(uri.host, uri.port)
	request = Net::HTTP::Post.new(uri.request_uri)
	request.body = request_body
	request.content_type = 'text/xml'
	response = http.start {|http| http.request(request) }
	response = response.body
	Mblox.log "Mblox responds with:\n#{response}"
	build_response(Hash.from_xml(response))
      end

      def build_response(result)
	result = result['NotificationRequestResult']
	result_header = result['NotificationResultHeader']
	subscriber_result = result['NotificationResultList']['NotificationResult']['SubscriberResult']
	"RequestResult: \"#{result_header['RequestResultCode']}:#{result_header['RequestResultText']}\" / SubscriberResult: \"#{subscriber_result['SubscriberResultCode']}:#{subscriber_result['SubscriberResultText']}\""
      end

      def build(message)
	builder = Builder::XmlMarkup.new
	builder.instruct!(:xml, :encoding => "ISO-8859-1")
	builder.NotificationRequest(:Version => "3.5") do |nr|
	  nr.NotificationHeader do |nh|
	    nh.PartnerName(Mblox.config.partner_name)
	    nh.PartnerPassword(Mblox.config.password)
	  end
	  nr.NotificationList(:BatchID => "1") do |nl|
	    nl.Notification(:SequenceNumber => "1", :MessageType => "SMS") do |n|
	      n.Message(message)
	      n.Profile(Mblox.config.profile_id)
	      n.SenderID(Mblox.config.sender_id, :Type => 'Shortcode')
	      n.Tariff(Mblox.config.tariff)
	      n.Subscriber do |s|
		s.SubscriberNumber(@phone)
	      end
	      n.ServiceId(Mblox.config.service_id)
	    end
	  end
	end
      end

      def self.split_message(message)
        sections = message.size / MAX_SECTION_LENGTH + 1
        Mblox.log "Splitting message into #{sections} messages due to length."
        split_message = []
        (sections - 1).times { |i| split_message << "(MSG #{i+1}/#{sections}): #{message[(i)*MAX_SECTION_LENGTH, MAX_SECTION_LENGTH]}" }
        split_message << "(MSG #{sections}/#{sections}): #{message[(sections-1)*MAX_SECTION_LENGTH..-1]}"
      end
  end
end
