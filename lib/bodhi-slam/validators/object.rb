module Bodhi
  class ObjectValidator < Validator
    
    def validate(record, attribute, value)
      unless value.nil?
        
        if value.is_a?(Array)
          unless value.empty?
            record.errors.add(attribute, "must contain only JSON Objects") unless value.delete_if{ |v| v.is_a? Hash }.empty?
          end
        else
          record.errors.add(attribute, "must be a JSON Object") unless value.is_a? Hash
        end
        
      end
    end
    
    def to_options
      {object: true}
    end
  end
end