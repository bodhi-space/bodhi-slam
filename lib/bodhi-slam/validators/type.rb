module Bodhi
  class TypeValidator < Validator
    attr_reader :type, :reference

    def initialize(type, reference=nil)
      if type.nil?
        raise ArgumentError.new("Expected :type to not be nil")
      end

      @type = type
      @reference = reference
    end

    def validate(record, attribute, value)
      unless value.nil?

        # Default values for comparators and messages
        klass = nil
        single_comparator = ->(item){ item.is_a? klass }
        array_comparator = ->(items){ items.delete_if{ |item| item.is_a? klass }.empty? }

        single_message = "must be a #{@type}"
        array_message = "must contain only #{@type}s"

        # Check what the given type is, and assign the correct comparator and messages
        case @type
        when "GeoJSON"
          klass = Hash
        when "Object"
          klass = Hash
        when "Real"
          klass = Float
        when "Boolean"
          single_comparator = ->(item){ item.is_a?(TrueClass) || item.is_a?(FalseClass) }
          array_comparator = ->(items){ items.delete_if{ |item| item.is_a?(TrueClass) || item.is_a?(FalseClass) }.empty? }
        when "Enumerated"
          klass = Object
        else # type is an embedded type
          klass = Object.const_get(@type)
        end

        # Do the validations and add any error messages
        if value.is_a?(Array)
          if !value.empty?
            if !array_comparator.call(value)
              record.errors.add(attribute, array_message)
            end
          end
        else
          if !single_comparator.call(value)
            record.errors.add(attribute, single_message)
          end
        end

        # Party time, excellent!
      end
    end

    def to_options
      if @reference.nil?
        {self.to_sym => @type}
      else
        {self.to_sym => @type, ref: @reference}
      end
    end
  end
end