require 'active_model/serialization'
require 'active_model/serializers/xml.rb'

require 'active_model/callbacks'
require 'active_model/validator'
require 'active_model/naming'
require 'active_model/translation'
require 'active_model/validations'
require 'active_model/errors'

module Mblox
  class SmsResponse
    class Result
      include ActiveModel::Validations
      validates_presence_of :text, :code, :message => "%{attribute} cannot be blank"
      validates_numericality_of :code, :only_integer => true, :allow_nil => true, :message => "%{attribute} must be an integer"

      attr_reader :code, :text
      def initialize(code, text)
        @code, @text = code, text
      end

      def is_ok?
        0 == @code
      end
    end
  end
end
