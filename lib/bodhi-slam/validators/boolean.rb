module Bodhi
  class BooleanValidator < Validator
    
    def validate(record, attribute, value)
      unless value.nil?
        
        if value.is_a?(Array)
          unless value.empty?
            record.errors.add(attribute, "must contain only Booleans") unless value.delete_if{ |v| v.is_a?(TrueClass) || v.is_a?(FalseClass) }.empty?
          end
        else
          record.errors.add(attribute, "must be a Boolean") unless value.is_a?(TrueClass) || value.is_a?(FalseClass)
        end
        
      end
    end
    
  end
end