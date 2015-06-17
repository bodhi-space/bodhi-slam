module Bodhi
  class TypeValidator < Validator
    attr_reader :type, :reference

    def initialize(type, reference=nil)
      if type.nil?
        raise ArgumentError.new("Expected :type to not be nil")
      end

      @type = type
      @reference = reference if reference
    end

    def validate(record, attribute, value)
      unless value.nil?

        # Default values for comparators and messages
        klass = nil
        single_comparator = ->(item){ item.is_a? klass }
        array_comparator = ->(items){ items.select{ |item| !item.is_a?(klass) }.empty? }
        single_message = "must be a #{@type}"
        array_message = "must contain only #{@type}s"

        # Check what the given type is, and assign the correct comparator and messages
        case @type
        when "GeoJSON"
          klass = Hash
        when "DateTime"
          single_comparator = lambda do |item|
            begin
              DateTime.iso8601(item)
            rescue
              false
            end
          end
          array_comparator = lambda do |items|
            begin
              items.collect{ |item| DateTime.iso8601(item) }
            rescue
              false
            end
          end
        when "Object"
          klass = Hash
          single_message = "must be a JSON object"
          array_message = "must contain only JSON objects"
        when "Real"
          klass = Float
        when "Boolean"
          single_comparator = ->(item){ item.is_a?(TrueClass) || item.is_a?(FalseClass) }
          array_comparator = ->(items){ items.delete_if{ |item| item.is_a?(TrueClass) || item.is_a?(FalseClass) }.empty? }
        when "Enumerated"
          if @reference.nil?
            raise RuntimeError.new("Enumerated reference is missing!  Cannot validate #{record.class}.#{attribute}=#{value}")
          end

          single_message = "must be a #{@reference}"
          array_message = "must contain only #{@reference} objects"

          name = @reference.split(".")[0]
          field = @reference.split(".")[1]

          enumeration = Bodhi::Enumeration.cache[name.to_sym]
          if field.nil?
            single_comparator = ->(item){ enumeration.values.include?(item) }
            array_comparator = ->(items){ items.select{ |item| !enumeration.values.include?(item) }.empty? }
          else
            flattened_values = enumeration.values.map{|val| val[field.to_sym] }
            single_comparator = ->(item){ flattened_values.include?(item) }
            array_comparator = ->(items){ items.select{ |item| !flattened_values.include?(item) }.empty? }
          end
        else # type is an embedded type
          klass = Object.const_get(@type)
        end

        # Do the validations and add any error messages
        if value.is_a?(Array)
          if !value.empty?
            if !array_comparator.call(value)
              record.errors.add(attribute, array_message)
            else # validate each value in the array if it responds to :valid?
              value.each_with_index do |item, index|
                if item.respond_to?(:valid?)
                  item.valid?
                  if item.errors.any?
                    item.errors.each do |error_attribute, message|
                      full_name = "#{attribute}[#{index}].#{error_attribute}".to_sym
                      record.errors.add(full_name, message)
                    end
                  end
                end
              end
            end
          end
        else
          if !single_comparator.call(value)
            record.errors.add(attribute, single_message)
          else # validate the value if it responds to :valid?
            if value.respond_to?(:valid?)
              value.valid?
              if value.errors.any?
                value.errors.each do |error_attribute, error|
                  full_path = "#{attribute}.#{error_attribute}".to_sym
                  record.errors.add(full_path, error)
                end
              end
            end
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