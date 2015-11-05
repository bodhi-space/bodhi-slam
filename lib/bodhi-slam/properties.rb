module Bodhi
  module Properties

    SYSTEM_PROPERTIES = [:sys_created_at, :sys_version, :sys_modified_at, :sys_modified_by,
      :sys_namespace, :sys_created_by, :sys_type_version, :sys_id, :sys_embeddedType]
    attr_accessor *SYSTEM_PROPERTIES

    module ClassMethods
      def properties; @properties; end
      def property(*names)
        attr_accessor *names.map(&:to_sym)
        @properties << names.map(&:to_sym)
        @properties.flatten!
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
      def initialize(params={})
        params.each do |param_key, param_value|
          send("#{param_key}=", param_value)
        end
      end

      # Returns a Hash of the class properties and their values.
      # 
      #   object = SomeResource.new(foo:"test", bar:12345)
      #   object.attributes # => { foo: "test", bar: 12345 }
      def attributes
        attributes = Hash.new
        self.class.properties.each do |property|
          attributes[property] = send(property)
        end

        attributes.delete_if { |k, v| v.nil? }
        attributes
      end

      # Returns all the classes properties as JSON.
      # It converts any nested objects to JSON if they respond to +to_json+
      # 
      #   resource = SomeResource.new(foo:"test", bar:12345)
      #   embedded_resources = AnotherResource.new( test: s )
      #   
      #   resource.to_json # => "{ 'foo':'test', 'bar':12345 }"
      #   embedded_resources.to_json # => "{ 'test': { 'foo':'test', 'bar':12345 } }"
      def to_json(base=nil)
        super if base
        attributes.to_json
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)
      base.instance_variable_set(:@properties, Array.new)
    end
  end
end