module Bodhi
  class UrlValidator < Validator

    def initialize(value); end

    def validate(record, attribute, value)
      unless value.nil?
        
        if value.is_a?(Array)
          unless value.empty?
            record.errors.add(attribute, "must contain only valid URLs") unless value.delete_if{ |v| v =~ /\A#{URI::regexp}\z/ }.empty?
          end
        else
          record.errors.add(attribute, "must be a valid URL") unless value =~ /\A#{URI::regexp}\z/
        end
        
      end
    end
    
    def to_options
      {self.to_sym => true}
    end
  end
end