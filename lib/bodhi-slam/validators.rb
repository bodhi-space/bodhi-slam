module Bodhi
  class Validator
    
    # Override this method in subclasses with validation logic, adding errors
    # to the records +errors+ array where necessary.
    def validate(record, attribute, value)
      raise NotImplementedError, "Subclasses must implement a validate(record, attribute, value) method."
    end
    
    # Calls +underscore+ on the validation and returns it's class name as a symbol.
    # Namespaces and the trailing "_validation" text will be trimmed
    # 
    # BaseValidation.to_sym # => :base
    # StringValidation.to_sym # => :string
    # NotBlankValidation.to_sym # => :not_blank
    def to_sym
      underscore.
      gsub("bodhi/", "").
      gsub("_validator", "").
      to_sym
    end
    
    # Returns the validation's class name in snake_case.
    #
    # BaseValidation.underscore # => "bodhi/base_validation"
    # StringValidation.underscore # => "bodhi/string_validation"
    # NotBlankValidation.underscore # => "bodhi/not_blank_validation"
    def underscore
      self.class.name.gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr("-", "_").
      downcase
    end
    
  end
end

Dir[File.dirname(__FILE__) + "/validators/*.rb"].each { |file| require file }