module Bodhi
  class MinValidator < Validator
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def validate(record, attribute, value)
      unless value.nil?

        if value.is_a?(Array)
          unless value.empty?
            record.errors.add(attribute, "must only contain values greater than #{@value}") unless value.delete_if{ |v| v > @value }.empty?
          end
        else
          record.errors.add(attribute, "must be a greater than #{@value}") unless value > @value
        end

      end
    end
    
    def to_options
      {min: @value}
    end
  end
end