module Bodhi
  class ValidationFactory
    def self.build(name)
      raise ArgumentError.new("Expected #{name.class} to be a Symbol") unless name.is_a? Symbol
      validation = nil
      
      case name
      when :required
        validation = Bodhi::RequiredValidation.new
      when :multi
        validation = Bodhi::MultiValidation.new
      when :not_blank
        validation = Bodhi::NotBlankValidation.new
      when :Object
        validation = Bodhi::ObjectValidation.new
      when :Boolean
        validation = Bodhi::BooleanValidation.new
      when :String
        validation = Bodhi::StringValidation.new
      when :Integer
        validation = Bodhi::IntegerValidation.new
      when :DateTime
        validation = Bodhi::DateTimeValidation.new
      when :Real
        validation = Bodhi::RealValidation.new
      when :GeoJSON
        validation = Bodhi::GeoJSONValidation.new
      when :Enumerated
        validation = Bodhi::EnumeratedValidation.new
      end
      
      validation
    end
  end
end