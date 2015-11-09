module Bodhi
  class Validator
    
    # Override this method in subclasses with validation logic, adding errors
    # to the records +errors+ array where necessary.
    def validate(record, attribute, value)
      raise NotImplementedError, "Subclasses must implement a validate(record, attribute, value) method."
    end
    
    # Calls +underscore+ on the validator and returns it's class name as a symbol.
    # Namespaces and the trailing "_validator" text will be trimmed
    # 
    #   type = Bodhi::TypeValidator.new("String")
    #   is_not_blank = Bodhi::IsNotBlankValidator.new(true)
    #
    #   type.to_sym # => :type
    #   is_not_blank.to_sym # => :is_not_blank
    def to_sym
      name = self.underscore.gsub("bodhi::", "").gsub("_validator", "")
      Bodhi::Support.reverse_camelize(name).to_sym
    end
    
    # Returns the validation's class name in snake_case.
    #
    #   type = Bodhi::TypeValidator.new("String")
    #   is_not_blank = Bodhi::IsNotBlankValidator.new(true)
    #
    #   type.underscore # => "bodhi/type_validator"
    #   is_not_blank.underscore # => "bodhi/is_not_blank_validator"
    def underscore
      Bodhi::Support.underscore(self.class.name)
    end
    
    # Returns the validation as an options Hash.
    # The options hash is suitable to be used in the Bodhi::Validations.valdiates method
    #
    #   type = Bodhi::TypeValidator.new("String")
    #   is_not_blank = Bodhi::IsNotBlankValidator.new(true)
    #
    #   type_validation.to_options # => { type: "String" }
    #   is_not_blank_validation.to_options # => { is_not_blank: true }
    def to_options
      raise NotImplementedError, "Subclasses must implement a to_options method."
    end

    # Returns the validator class with the given +name+
    # Raises NameError if no validator class is found
    # 
    #   Bodhi::Validator.constantize("type") # => #<Bodhi::TypeValidator:0x007fbff403e808>
    #   Bodhi::Validator.constantize("is_not_blank") # => #<Bodhi::IsNotBlankValidator:0x007fbff403e808>
    def self.constantize(name)
      camelized_name = Bodhi::Support.camelize(name.to_s)
      Object.const_get("Bodhi::#{camelized_name}Validator")
    end
  end
end

Dir[File.dirname(__FILE__) + "/validators/*.rb"].each { |file| require file }