module Bodhi
  class RequiredValidator < Validator
    
    def validate(record, attribute, value)
      record.errors.add(attribute, "is required") if value.nil?
    end
    
  end
end