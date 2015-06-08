module Bodhi
  class ValidationFactory    
    def self.build(attribute)
      if !attribute.is_a? Hash
        raise ArgumentError.new("Expected #{attribute.class} to be a Hash")
      elsif attribute[:type].nil?
        raise ArgumentError.new("Missing key :type")
      end
      
      validations = []
      type = attribute[:type].to_sym
      case type
      when :Object
        validations << Bodhi::ObjectValidation.new
      when :Boolean
        validations << Bodhi::BooleanValidation.new
      when :String
        validations << Bodhi::StringValidation.new
      when :Integer
        validations << Bodhi::IntegerValidation.new
      when :DateTime
        validations << Bodhi::DateTimeValidation.new
      when :Real
        validations << Bodhi::RealValidation.new
      when :GeoJSON
        validations << Bodhi::GeoJSONValidation.new
      when :Enumerated
        validations << Bodhi::EnumeratedValidation.new(attribute[:ref])
      else #Embedded Doc
        validations << Bodhi::EmbeddedValidation.new(type)
      end
      
      if attribute[:required]
        validations << Bodhi::RequiredValidation.new
      end
      
      if attribute[:multi]
        validations << Bodhi::MultiValidation.new
      end
      
      if attribute[:isNotBlank]
        validations << Bodhi::NotBlankValidation.new
      end
      
      validations
    end
  end
end