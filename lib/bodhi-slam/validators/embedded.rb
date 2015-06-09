module Bodhi
  class EmbeddedValidator < Validator
    attr_reader :klass
    
    def initialize(klass)
      @klass = klass
    end
    
    def validate(record, attribute, value)
      unless value.nil?
        
        if value.is_a?(Array)
          unless value.empty?
            record.errors.add(attribute, "must contain only #{klass} objects") unless value.delete_if{ |v| v.is_a? Object.const_get(@klass) }.empty?
          end
        else
          record.errors.add(attribute, "must be a #{klass}") unless value.is_a? Object.const_get(@klass)
        end
        
      end
    end
    
  end
end