module Bodhi
  class NotBlankValidator < Validator
    
    def validate(record, attribute, value)
      unless value.nil?
        record.errors.add(attribute, "can not be blank") if value.empty?
      end
    end
    
  end
end