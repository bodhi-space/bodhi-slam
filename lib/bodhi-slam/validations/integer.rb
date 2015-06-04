module Bodhi
  class IntegerValidation < BaseValidation
    
    def validate(record, attribute, value)
      unless value.nil?
        record.errors.add(attribute, "must be an Integer") unless value.is_a? Integer
      end
    end
    
  end
end