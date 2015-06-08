module Bodhi
  class EmbeddedValidator < Validator
    attr_reader :klass
    
    def initialize(klass)
      @klass = klass
    end
    
    def validate(record, attribute, value)
      unless value.nil?
        record.errors.add(attribute, "must be a #{klass}") unless value.is_a? Object.const_get(@klass)
      end
    end
    
  end
end