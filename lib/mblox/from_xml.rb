require 'active_model/serialization'
require 'active_model/serializers/xml.rb'

module Mblox
  class MissingExpectedXmlContentError < StandardError; end

  class << self
    def from_xml(xml)
      begin
        Hash.from_xml(xml)
      rescue REXML::ParseException
        raise MissingExpectedXmlContentError, "'#{xml}' is not parseable as XML"
      end
    end
  end
end
