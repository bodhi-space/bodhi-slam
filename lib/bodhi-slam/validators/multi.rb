module Bodhi
  class MultiValidator < Validator

    def initialize(value); end

    def validate(record, attribute, value)
      if value.nil?
        #do nothing
      else
        record.errors.add(attribute, "must be an array") unless value.is_a? Array
      end
    end

    def to_options
      {self.to_sym => true}
    end
  end
end