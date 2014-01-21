require 'nokogiri'

module Mblox
  class MissingExpectedXmlContentError < StandardError; end
  class ValidationError < StandardError; end

  class << self
    def from_xml(xml)
      Nokogiri::XML(xml) { |config| config.nonet }.tap do |_|
        raise MissingExpectedXmlContentError, "'#{xml}' is not parseable as XML" unless _.errors.empty?
      end
    end
  end
end
