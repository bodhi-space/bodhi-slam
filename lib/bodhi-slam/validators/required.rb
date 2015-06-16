module Bodhi
  class RequiredValidator < Validator

    def initialize(value); end

    def validate(record, attribute, value)
      record.errors.add(attribute, "is required") if value.nil?
    end
    
    def to_options
      {required: true}
    end
  end
end