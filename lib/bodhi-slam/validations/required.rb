module Bodhi
  class RequiredValidation < BaseValidation
    
    def validate(record, attribute, value)
      record.errors.add(attribute, "is required") if value.nil?
    end
    
  end
end