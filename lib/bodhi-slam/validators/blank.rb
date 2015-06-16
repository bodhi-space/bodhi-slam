module Bodhi
  class IsNotBlankValidator < Validator

    def initialize(value); end

    def validate(record, attribute, value)
      unless value.nil?
        
        if value.is_a?(Array)
          unless value.empty?
            record.errors.add(attribute, "must not contain blank Strings") unless value.delete_if{ |v| !v.empty? }.empty?
          end
        else
          record.errors.add(attribute, "can not be blank") if value.empty?
        end
        
      end
    end
    
    def to_options
      {self.to_sym => true}
    end
  end
end