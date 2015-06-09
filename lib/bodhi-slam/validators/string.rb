module Bodhi
  class StringValidator < Validator
    
    def validate(record, attribute, value)
      unless value.nil?
        
        if value.is_a?(Array)
          unless value.empty?
            record.errors.add(attribute, "must contain only Strings") unless value.delete_if{ |v| v.is_a? String }.empty?
          end
        else
          record.errors.add(attribute, "must be a String") unless value.is_a? String
        end
        
      end
    end
    
  end
end