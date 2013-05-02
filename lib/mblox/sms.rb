require 'active_support/core_ext/hash'
require 'addressable/uri'
require 'builder'
require "net/https"

module Mblox
  class Sms
    attr_reader :phone, :message
    def initialize(phone,message)
      phone = phone.to_s
      raise SmsError, "Phone number must be ten digits" unless /\A[0-9]{10}\z/.match(phone)
      raise SmsError, "Phone number cannot begin with 0 or 1" if ['0','1'].include?(phone[0].to_s)
      raise SmsError, "Message cannot be blank" if message.empty?
      if message.size > 160
        raise SmsError, "Message cannot be longer than 160 characters" if :raise_error == Mblox.config.on_message_too_long
        Mblox.log "Truncating message due to length.  Message was:\n#{message} but will now be#{message = message[0,160]}" if :truncate == Mblox.config.on_message_too_long
      end
      @phone = "1#{phone}"
      @message = message.dup
    end

    def send
      commit build
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

      def build
	builder = Builder::XmlMarkup.new
	builder.instruct!(:xml, :encoding => "ISO-8859-1")
	builder.NotificationRequest(:Version => "3.5") do |nr|
	  nr.NotificationHeader do |nh|
	    nh.PartnerName(Mblox.config.partner_name)
	    nh.PartnerPassword(Mblox.config.password)
	  end
	  nr.NotificationList(:BatchID => "1") do |nl|
	    nl.Notification(:SequenceNumber => "1", :MessageType => "SMS") do |n|
	      n.Message(@message)
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
  end
end
