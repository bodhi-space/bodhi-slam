module Bodhi
  module Properties

    SYSTEM_PROPERTIES = [:sys_created_at, :sys_version, :sys_modified_at, :sys_modified_by,
      :sys_namespace, :sys_created_by, :sys_type_version, :sys_id, :sys_embeddedType]
    attr_accessor *SYSTEM_PROPERTIES

    module ClassMethods
      def properties; @properties; end
      def property_names; @properties.keys; end
      def property(name, options)
        attr_accessor name.to_sym
        @properties[name.to_sym] = options.reduce({}) do |memo, (k, v)|
          memo.merge({ Bodhi::Support.reverse_camelize(k.to_s).to_sym => v})
        end
      end
    end

    module InstanceMethods
      def id; @sys_id; end
      def persisted?; !@sys_id.nil?; end
      def new_record?; @sys_id.nil?; end

      # Initializes a new instance of the class.  Accepts a parameter Hash for mass assignment.
      # If a parameter does not exist for the class, an UndefinedMethod error is raised.
      #
      #   klass = Class.new do
      #     include Bodhi::Properties
      #     property :name, :email
      #   end
      #
      #   object = klass.new(name: "Bob", email: "some@email.com")
      #   object.name #=> "Bob"
      #   object.email #=> "some@email.com"
      def initialize(options={})
        options = Bodhi::Support.symbolize_keys(options)

        options.each do |property, value|
          property_options = self.class.properties[property]
          if property_options.nil?
            send("#{property}=", value)
          else
            send("#{property}=", Bodhi::Support.coerce(value, property_options))
          end
        end
      end

      # Returns a Hash of the class properties and their values.
      # 
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
          else
            attributes[property] = value
          end
        end

        attributes.delete_if { |k, v| v.nil? }
        attributes
      end

      # Updates the resource with the given attributes Hash
      # 
      #   s = SomeResource.factory.build(foo:"test", bar:12345)
      #   s.attributes # => { foo: "test", bar: 12345 }
      #   s.update_attributes(bar: 10)
      #   s.attributes # => { foo: "test", bar: 10 }
      def update_attributes(params)
        params.each do |param_key, param_value|
          send("#{param_key}=", param_value)
        end
      end

      # Returns all the classes properties as JSON.
      # It converts any nested objects to JSON if they respond to +to_json+
      # 
      #   resource = SomeResource.new(foo:"test", bar:12345)
      #   embedded_resources = AnotherResource.new( test: resource )
      #   
      #   resource.to_json # => "{ 'foo':'test', 'bar':12345 }"
      #   embedded_resources.to_json # => "{ 'test': { 'foo':'test', 'bar':12345 } }"
      def to_json(base=nil)
        attributes.to_json
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)
      base.instance_variable_set(:@properties, Hash.new)
    end
  end
end