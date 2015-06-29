module Bodhi
  class MultiValidator < Validator

    def initialize(value); end

    def validate(record, attribute, value)
      record.errors.add(attribute, "must be an array") unless value.is_a? Array
    end

    def to_options
      {self.to_sym => true}
    end
  end
end