module Bodhi
  class GeoJSONValidation < BaseValidation
    
    def validate(record, attribute, value)
      unless value.nil?
        record.errors.add(attribute, "must be a GeoJSON") unless value.is_a? Hash
      end
    end
    
  end
end