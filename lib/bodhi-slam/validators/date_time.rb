module Bodhi
  class DateTimeValidator < Validator
    
    def validate(record, attribute, value)
      unless value.nil?
        record.errors.add(attribute, "must be a DateTime") unless value.is_a? Time
      end
    end
    
  end
end