module Bodhi
  class EnumeratedValidator < Validator
    attr_reader :reference
    
    def initialize(reference, values=[])
      @reference = reference
      @values = values
    end
    
    def validate(record, attribute, value)
      unless value.nil?
        
        if value.is_a?(Array)
          unless value.empty?
            record.errors.add(attribute, "must contain only #{@reference} values") unless value.delete_if{ |v| @values.include?(v) }.empty?
          end
        else
          record.errors.add(attribute, "is not a #{@reference}") unless @values.include?(value)
        end
        
      end
    end
    
  end
end