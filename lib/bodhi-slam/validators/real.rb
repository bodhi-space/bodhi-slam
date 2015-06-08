module Bodhi
  class RealValidator < Validator
    
    def validate(record, attribute, value)
      unless value.nil?
        record.errors.add(attribute, "must be a Real (Float)") unless value.is_a? Float
      end
    end
    
  end
end