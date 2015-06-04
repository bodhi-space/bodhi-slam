module Bodhi
  class StringValidation < BaseValidation
    
    def validate(record, attribute, value)
      unless value.nil?
        record.errors.add(attribute, "must be a String") unless value.is_a? String
      end
    end
    
  end
end