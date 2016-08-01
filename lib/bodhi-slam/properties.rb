module Bodhi
  # The Bodhi::Properties module is intended to help
  module Properties

    # Default properties for ALL records on the IoT Platform
    SYSTEM_PROPERTIES = [:sys_created_at, :sys_version, :sys_modified_at, :sys_modified_by,
      :sys_namespace, :sys_created_by, :sys_type_version, :sys_id, :sys_embeddedType]
    attr_accessor *SYSTEM_PROPERTIES

    module ClassMethods
      # Retuns a Hash of the Classes properties
      # @return [Hash] The classes properties and options
      def properties; @properties; end

      # A list of all property names
      # @return [Array<String>]
      def property_names; @properties.keys; end

      # Set a new property with the given +name+ and +options+
      # @param name [String, Symbol]
      # @param options [Hash]
      # @return [nil]
      # @example
      #   Resource.property("age", type: Integer, required: true, min: 18)
      #   Resource.property("birthday", type: DateTime, required: true)
      #   Resource.property(:tags, type: String, multi: true)
      #   Resource.property(:dogs", type: "Dog", multi: true)
      def property(name, options)
        attr_accessor name.to_sym
        @properties[name.to_sym] = options.reduce({}) do |memo, (k, v)|
          memo.merge({ Bodhi::Support.reverse_camelize(k.to_s).to_sym => v})
        end

        return nil
      end
    end

    module InstanceMethods
      # Wraps the sys_id property into a more Rails friendly attribute
      # @return [String]
      def id; @sys_id; end

      # Returns +true+ if the record has been saved to the IoT Platform
      # @return [Boolean]
      def persisted?; !@sys_id.nil?; end

      # Returns +true+ if the record has +NOT+ been saved to the IoT Platform
      # @return [Boolean]
      def new_record?; @sys_id.nil?; end

      # Override Enumerable#each
      # @deprecated I dont think this should be used in this context.  Will be removed/refactored shortly
      def each; attributes.each{ |k, v| yield(k, v) }; end

      # Initializes a new instance of the class.  Accepts a parameter Hash for mass assignment.
      #
      # @param options [Hash]
      # @example
      #   klass = Class.new do
      #     include Bodhi::Properties
      #     property :name, :email
      #   end
      #
      #   object = klass.new(name: "Bob", email: "some@email.com")
      #   object.name #=> "Bob"
      #   object.email #=> "some@email.com"
      def initialize(options={})
        if options.is_a?(String)
          options = JSON.parse(options)
        end

        # Set properties defined by the +options+ parameter
        options = Bodhi::Support.symbolize_keys(options)
        options.each do |property, value|
          property_options = self.class.properties[property]
          if property_options.nil?
            send("#{property}=", value)
          else
            send("#{property}=", Bodhi::Support.coerce(value, property_options))
          end
        end

        # Set any default values
        self.class.properties.select{ |k,v| !v[:default].nil? }.each do |property, property_options|
          send("#{property}=", property_options[:default]) if send("#{property}").nil?
        end
      end

      # Returns a Hash of the class properties and their values.
      #
      # @return [Hash]
      # @example
      #   object = SomeResource.new(foo:"test", bar:12345)
      #   object.attributes # => { foo: "test", bar: 12345 }
      def attributes
        attributes = Hash.new

        self.class.property_names.each do |property|
          value = send(property)
          if value.respond_to?(:attributes)
            attributes[property] = value.attributes.delete_if { |k, v| v.nil? }
          elsif value.is_a?(Array) && value.first.respond_to?(:attributes)
            attributes[property] = value.map(&:attributes).collect{ |item| item.delete_if { |k, v| v.nil? } }
          elsif value.is_a?(Time)
            attributes[property] = value.iso8601
          else
            attributes[property] = value
          end
        end

        attributes.delete_if { |k, v| v.nil? }
        attributes
      end

      # Updates the resource with the given attributes Hash
      #
      # @param properties [Hash] The properties to update
      # @return [nil]
      # @example
      #   s = SomeResource.factory.build(foo:"test", bar:12345)
      #   s.attributes # => { foo: "test", bar: 12345 }
      #   s.update_attributes(bar: 10)
      #   s.attributes # => { foo: "test", bar: 10 }
      def update_attributes(properties)
        properties.each do |property, value|
          property_options = self.class.properties[property.to_sym]
          if property_options.nil?
            send("#{property}=", value)
          else
            send("#{property}=", Bodhi::Support.coerce(value, property_options))
          end
        end

        return nil
      end

      # Returns all the classes properties as JSON.
      # It converts any nested objects to JSON if they respond to +to_json+
      #
      # @param options [Hash]
      # @return [String] the JSON for all properties on the object
      # @example
      #   resource = SomeResource.new(foo:"test", bar:12345)
      #   embedded_resources = AnotherResource.new( test: resource )
      #
      #   resource.to_json # => "{ 'foo':'test', 'bar':12345 }"
      #   embedded_resources.to_json # => "{ 'test': { 'foo':'test', 'bar':12345 } }"
      def to_json(options=nil)
        attributes.to_json
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods, Enumerable)
      base.instance_variable_set(:@properties, Hash.new)
    end
  end
end
