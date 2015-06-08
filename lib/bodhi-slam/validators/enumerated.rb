module Bodhi
  class EnumeratedValidator < Validator
    attr_reader :reference
    
    def initialize(reference, values=[])
      @reference = reference
      @values = values
    end
    
    def validate(record, attribute, value)
      unless value.nil?
        record.errors.add(attribute, "is not a #{@reference}") unless @values.include?(value)
      end
    end
    
  end
end