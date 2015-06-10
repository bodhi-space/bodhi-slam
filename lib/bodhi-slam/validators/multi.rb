module Bodhi
  class MultiValidator < Validator
    
    def validate(record, attribute, value)
      record.errors.add(attribute, "must be an array") unless value.is_a? Array
    end
    
    def to_options
      {multi: true}
    end
  end
end