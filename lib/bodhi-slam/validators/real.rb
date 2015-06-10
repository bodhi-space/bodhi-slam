module Bodhi
  class RealValidator < Validator
    
    def validate(record, attribute, value)
      unless value.nil?
        
        if value.is_a?(Array)
          unless value.empty?
            record.errors.add(attribute, "must contain only Real (Float) numbers") unless value.delete_if{ |v| v.is_a? Float }.empty?
          end
        else
          record.errors.add(attribute, "must be a Real (Float)") unless value.is_a? Float
        end
        
      end
    end
    
    def to_options
      {real: true}
    end
  end
end