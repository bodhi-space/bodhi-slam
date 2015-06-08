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
        validations << Bodhi::ObjectValidator.new
      when :Boolean
        validations << Bodhi::BooleanValidator.new
      when :String
        validations << Bodhi::StringValidator.new
      when :Integer
        validations << Bodhi::IntegerValidator.new
      when :DateTime
        validations << Bodhi::DateTimeValidator.new
      when :Real
        validations << Bodhi::RealValidator.new
      when :GeoJSON
        validations << Bodhi::GeoJsonValidator.new
      when :Enumerated
        validations << Bodhi::EnumeratedValidator.new(attribute[:ref])
      else #Embedded Doc
        validations << Bodhi::EmbeddedValidator.new(type)
      end
      
      if attribute[:required]
        validations << Bodhi::RequiredValidator.new
      end
      
      if attribute[:multi]
        validations << Bodhi::MultiValidator.new
      end
      
      if attribute[:isNotBlank]
        validations << Bodhi::NotBlankValidator.new
      end
      
      validations
    end
  end
end