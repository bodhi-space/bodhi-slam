module Bodhi
  class PrecisionValidator < Validator
    attr_reader :number

    def initialize(number)
      if number.nil?
        raise ArgumentError.new("Expected :number to not be nil")
      end
      @number = number
    end

    def validate(record, attribute, value)
      unless value.nil?
        
        if value.is_a?(Array)
          unless value.empty?
            record.errors.add(attribute, "must contain only values with #{@number} decimal points") unless value.delete_if{ |v| decimals(v) == @number }.empty?
          end
        else
          record.errors.add(attribute, "must have #{@number} decimal points") if decimals(value) != @number
        end
        
      end
    end
    
    def to_options
      {self.to_sym => @number}
    end

    private
    def decimals(a)
      num = 0
      while(a != a.to_i)
        num += 1
        a *= 10
      end
      num   
    end
  end
end