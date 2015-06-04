module Bodhi
  class ObjectValidation < BaseValidation
    
    def validate(record, attribute, value)
      unless value.nil?
        record.errors.add(attribute, "must be a JSON Object") unless value.is_a? Hash
      end
    end
    
  end
end