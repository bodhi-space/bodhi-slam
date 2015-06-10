module Bodhi
  class IntegerValidator < Validator
    
    def validate(record, attribute, value)
      unless value.nil?
        
        if value.is_a?(Array)
          unless value.empty?
            record.errors.add(attribute, "must contain only Integers") unless value.delete_if{ |v| v.is_a? Integer }.empty?
          end
        else
          record.errors.add(attribute, "must be an Integer") unless value.is_a? Integer
        end
        
      end
    end
    
    def to_options
      {integer: true}
    end
  end
end