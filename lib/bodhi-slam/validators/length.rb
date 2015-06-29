module Bodhi
  class LengthValidator < Validator
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def validate(record, attribute, value)
      unless value.nil?
        
        if value.is_a?(Array)
          unless value.empty?
            record.errors.add(attribute, "must all be #{value} characters long") unless value.select{ |item| !item.length == @value }.empty?
          end
        else
          record.errors.add(attribute, "must be #{value} characters long") unless value.length == @value
        end
        
      end
    end
    
    def to_options
      {self.to_sym => @value}
    end
  end
end