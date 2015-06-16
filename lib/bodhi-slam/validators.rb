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
    
    # Returns the validation as an options Hash.
    # The options hash is suitable to be used in the Bodhi::Validations.valdiates method
    #
    # StringValidation.to_options # => { string: true }
    # EmbeddedValidation.to_options # => { embedded: "ClassName" }
    # EnumeratedValidation.to_options # => { enumerated: "Country.name" }
    def to_options
      raise NotImplementedError, "Subclasses must implement a to_options method."
    end

    # Returns the validator class with the given +name+
    # Raises NameError if no validator class is found
    # 
    # Bodhi::Validator.constantize("type") # => Bodhi::TypeValidator
    # Bodhi::Validator.constantize("multi") # => Bodhi::MutliValidator
    # Bodhi::Validator.constantize("required") # => Bodhi::RequriedValidator
    def self.constantize(name)
      camelized_name = name.to_s.split('_').collect(&:capitalize).join
      full_name = "Bodhi::#{camelized_name}Validator"      
      Object.const_get(full_name)
    end
  end
end

Dir[File.dirname(__FILE__) + "/validators/*.rb"].each { |file| require file }