module Bodhi
  class TypeValidation < BaseValidation
    attr_reader :type
    
    def initialize(type_name)
      @type = type_name
    end
    
    def validate(record, attribute, value)
      klass = Object.const_get(type)
      record.errors.add(attribute, "must be a #{type}") unless value.is_a? klass
    end
    
  end
end