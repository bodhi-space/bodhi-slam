module Bodhi
  class BooleanValidation < BaseValidation
    
    def validate(record, attribute, value)
      unless value.nil?
        record.errors.add(attribute, "must be a Boolean") unless value.is_a?(TrueClass) || value.is_a?(FalseClass)
      end
    end
    
  end
end