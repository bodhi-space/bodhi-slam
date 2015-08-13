module Bodhi
  class Type
    include Bodhi::Validations

    SYSTEM_ATTRIBUTES = [:sys_created_at, :sys_version, :sys_modified_at, :sys_modified_by,
      :sys_namespace, :sys_created_by, :sys_type_version, :sys_id, :sys_embeddedType]
    ATTRIBUTES = [:name, :namespace, :package, :embedded, :properties, :version, :extends]

    attr_accessor *ATTRIBUTES
    attr_reader *SYSTEM_ATTRIBUTES
    attr_accessor :bodhi_context

    validates :name, required: true, is_not_blank: true
    validates :namespace, required: true
    validates :properties, required: true

    # Returns a factory for the Bodhi::Type class
    def self.factory
      @factory ||= Bodhi::Factory.new(Bodhi::Type).tap do |factory|
        factory.add_generator(:extends, type: "String", matches: "[a-zA-Z\\-_]{5,25}")
        factory.add_generator(:name, type: "String", required: true, is_not_blank: true)
        factory.add_generator(:namespace, type: "String", required: true)
        factory.add_generator(:properties, type: "Object", required: true)
        factory.add_generator(:package, type: "String")
        factory.add_generator(:embedded, type: "Boolean")
        factory.add_generator(:version, type: "String")
      end
    end

    def initialize(params={})
      # same as symbolize_keys!
      params = params.reduce({}) do |memo, (k, v)| 
        memo.merge({ k.to_sym => v})
      end

      # set attributes
      ATTRIBUTES.each do |attribute|
        send("#{attribute}=", params[attribute])
      end

      # Format type name to be compatible with Ruby Constants
      if !name.nil? && name[0] == name[0].downcase
        name.capitalize!
      end
    end

    # Returns a Hash of the Objects form attributes
    # 
    #   s = SomeResource.factory.build({foo:"test", bar:12345})
    #   s.attributes # => { foo: "test", bar: 12345 }
    def attributes
      result = Hash.new
      ATTRIBUTES.each do |attribute|
        result[attribute] = send(attribute)
      end
      result.delete_if { |k, v| v.nil? }
      result
    end

    # Returns all the Objects attributes as JSON.
    # It converts any nested Objects to JSON if they respond to +to_json+
    # 
    #   s = SomeResource.factory.build({foo:"test", bar:12345})
    #   s.to_json # => "{ 'foo':'test', 'bar':12345 }"
    def to_json(base=nil)
      super if base
      attributes.to_json
    end

    # Saves the resource to the Bodhi Cloud.  Raises ArgumentError if record could not be saved.
    # 
    #   obj = Resouce.new
    #   obj.save!
    #   obj.persisted? # => true
    def save!
      result = bodhi_context.connection.post do |request|
        request.url "/#{bodhi_context.namespace}/types"
        request.headers['Content-Type'] = 'application/json'
        request.headers[bodhi_context.credentials_header] = bodhi_context.credentials
        request.body = attributes.to_json
      end

      if result.status != 201
        raise Bodhi::ApiErrors.new(body: result.body, status: result.status), "status: #{result.status}, body: #{result.body}"
      end
    end

    def delete!
      result = bodhi_context.connection.delete do |request|
        request.url "/#{bodhi_context.namespace}/types/#{name}"
        request.headers[bodhi_context.credentials_header] = bodhi_context.credentials
      end

      if result.status != 204
        raise Bodhi::ApiErrors.new(body: result.body, status: result.status), "status: #{result.status}, body: #{result.body}"
      end
    end

    # Queries the Bodhi API for the given +type_name+ and
    # returns a Bodhi::Type
    # 
    #   context = BodhiContext.new(valid_params)
    #   type = Bodhi::Type.find(context, "MyTypeName")
    #   type # => #<Bodhi::Type:0x007fbff403e808 @name="MyTypeName">
    def self.find(context, type_name)
      if context.invalid?
        raise Bodhi::ContextErrors.new(context.errors.messages), context.errors.to_a.to_s
      end

      result = context.connection.get do |request|
        request.url "/#{context.namespace}/types/#{type_name}"
        request.headers[context.credentials_header] = context.credentials
      end

      if result.status != 200
        raise Bodhi::ApiErrors.new(body: result.body, status: result.status), "status: #{result.status}, body: #{result.body}"
      end

      type = Bodhi::Type.new(JSON.parse(result.body))
      type.bodhi_context = context
      type
    end

    # Queries the Bodhi API for all types within the given +context+ and
    # returns an array of Bodhi::Type objects
    # 
    #   context = BodhiContext.new(valid_params)
    #   types = Bodhi::Type.find_all(context)
    #   types # => [#<Bodhi::Type:0x007fbff403e808 @name="MyType">, #<Bodhi::Type:0x007fbff403e808 @name="MyType2">, ...]
    def self.find_all(context)
      if context.invalid?
        raise Bodhi::ContextErrors.new(context.errors.messages), context.errors.to_a.to_s
      end

      page = 1
      all_records = []

      begin
        result = context.connection.get do |request|
          request.url "/#{context.namespace}/types?paging=page:#{page}"
          request.headers[context.credentials_header] = context.credentials
        end

        if result.status != 200
          raise Bodhi::ApiErrors.new(body: result.body, status: result.status), "status: #{result.status}, body: #{result.body}"
        end

        page += 1
        records = JSON.parse(result.body)
        all_records << records
      end while records.size == 100

      all_records.flatten.collect do |type|
        record = Bodhi::Type.new(type)
        record.bodhi_context = context
        record
      end
    end

    # Dynamically defines a new Ruby class for the given +type+
    # Class validations, factory, and helper methods will also be added
    # 
    #   type = Bodhi::Type.new({name: "TestType", properties: { foo:{ type:"String" }}})
    #   klass = Bodhi::Type.create_class_with(type)
    #   klass # => #<Class:0x007fbff403e808 @name="TestType">
    #   klass.validations # => { foo: [#<TypeValidator:0x007fbff403e808 @type="String">] }
    #   klass.factory # => #<Bodhi::Factory:0x007fbff403e808 @klass="TestType", @generators=[]>
    def self.create_class_with(type)
      unless type.is_a? Bodhi::Type
        raise ArgumentError.new("Expected #{type.class} to be a Bodhi::Type")
      end

      klass = Object.const_set(type.name, Class.new {
        include Bodhi::Resource
        attr_accessor *type.properties.keys
      })

      type.properties.each_pair do |attr_name, attr_properties|
        attr_properties.delete_if{ |key, value| ["system", "trim", "unique", "default", "isCurrentUser"].include?(key) }
        klass.validates(attr_name.to_sym, attr_properties)
        klass.factory.add_generator(attr_name.to_sym, attr_properties)
      end

      klass
    end

  end
end