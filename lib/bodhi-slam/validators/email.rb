module Bodhi
  class IsEmailValidator < Validator
    
    def validate(record, attribute, value)
      unless value.nil?
        
        if value.is_a?(Array)
          unless value.empty?
            record.errors.add(attribute, "must only contain valid email addresses") unless value.delete_if{ |v| v =~ /.+@.+\..+/i }.empty?
          end
        else
          record.errors.add(attribute, "must be a valid email address") unless value =~ /.+@.+\..+/i
        end
        
      end
    end
    
    def to_options
      {not_blank: true}
    end
  end
end