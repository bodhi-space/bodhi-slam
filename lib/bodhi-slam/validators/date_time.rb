module Bodhi
  class DateTimeValidator < Validator
    
    def validate(record, attribute, value)
      unless value.nil?
        
        if value.is_a?(Array)
          unless value.empty?
            record.errors.add(attribute, "must contain only DateTimes") unless value.delete_if{ |v| v.is_a? Time }.empty?
          end
        else
          record.errors.add(attribute, "must be a DateTime") unless value.is_a? Time
        end
        
      end
    end
    
    def to_options
      {date_time: true}
    end
  end
end