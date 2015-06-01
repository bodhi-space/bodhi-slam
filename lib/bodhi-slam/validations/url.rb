module Bodhi
  class URLValidation < BaseValidation
    
    def validate(record, attribute, value)
      record.errors.add(attribute, "must be a valid URL") unless value =~ /\A#{URI::regexp}\z/
    end
    
  end
end