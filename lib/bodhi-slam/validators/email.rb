module Bodhi
  class IsEmailValidator < Validator

    def initialize(value); end

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
      {self.to_sym => true}
    end
  end
end