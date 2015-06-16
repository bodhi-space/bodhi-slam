module Bodhi
  class MatchesValidator < Validator
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def validate(record, attribute, value)
      unless value.nil?

        if value.is_a?(Array)
          unless value.empty?
            record.errors.add(attribute, "must only contain values matching #{@value}") unless value.delete_if{ |v| v.match(@value) }.empty?
          end
        else
          record.errors.add(attribute, "must be a greater than #{@value}") unless value.match(@value)
        end

      end
    end
    
    def to_options
      {matches: @value}
    end
  end
end