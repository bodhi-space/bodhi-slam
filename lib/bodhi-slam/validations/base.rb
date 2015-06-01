module Bodhi
  class BaseValidation
    
    # Override this method in subclasses with validation logic, adding errors
    # to the records +errors+ array where necessary.
    def validate(record, attribute, value)
      raise NotImplementedError, "Subclasses must implement a validate(record, attribute, value) method."
    end
    
  end
end