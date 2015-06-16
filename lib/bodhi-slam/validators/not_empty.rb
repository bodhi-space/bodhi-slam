module Bodhi
  class IsNotEmptyValidator < Validator

    def initialize(value); end

    def validate(record, attribute, value)
      unless value.nil?

        if value.is_a?(Array)
          record.errors.add(attribute, "must not be empty") if value.empty?
        end

      end
    end
    
    def to_options
      {self.to_sym => true}
    end
  end
end