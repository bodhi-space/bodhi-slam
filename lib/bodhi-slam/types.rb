module Bodhi
  # Interface for interacting with the BodhiType resource.
  class Type
    include Bodhi::Factories
    include Bodhi::Properties
    include Bodhi::Validations

    # The API context that binds this {Bodhi::Type} instance to the HotSchedules IoT Platform
    # @note This is required for the all instance methods to work correctly
    # @return [Bodhi::Context] the API context linked to this object
    attr_accessor :bodhi_context

    property :properties,     type: "Object"
    property :indexes,        type: "Bodhi::TypeIndex", multi: true
    property :events,         type: "Object"

    property :name,           type: "String"
    property :storage_name,   type: "String"
    property :namespace,      type: "String"
    property :package,        type: "String"
    property :version,        type: "String"
    property :extends,        type: "String"

    property :hidden,         type: "Boolean"
    property :embedded,       type: "Boolean"
    property :metadata,       type: "Boolean"
    property :encapsulated,   type: "Boolean"

    property :documentation,  type: "Link"

    validates :name, required: true, is_not_blank: true
    validates :properties, required: true
    validates :indexes, type: "Bodhi::TypeIndex", multi: true

    generates :name, type: "String", required: true, is_not_blank: true
    generates :namespace, type: "String", required: true
    generates :properties, type: "Object", required: true
    generates :package, type: "String"
    generates :embedded, type: "Boolean"
    generates :version, type: "String"

    # POST a new +Bodhi::Type+ to the HotSchedules IoT Platform
    #
    # Equivalent CURL command:
    #   curl -u username:password -X POST -H "Content-Type: application/json" \
    #     https://{server}/{namespace}/types \
    #     -d '{type properties}'
    #
    # @raise [RuntimeError] if the {#bodhi_context} attribute is nil
    # @raise [Bodhi::ContextErrors] if the {#bodhi_context} attribute is not valid
    # @raise [Bodhi::ApiErrors] if the response status is NOT +201+
    # @return [nil]
    # @example
    #   type = Bodhi::Type.new(bodhi_context: context, name: "MyType", properties: { name: { type: "String" }, age: { type: "Integer" } })
    #   type.save!
    def save!
      if bodhi_context.nil?
        raise RuntimeError.new("Missing attribute #bodhi_context.  Unable to send HTTP request")
      elsif bodhi_context.invalid?
        raise Bodhi::ContextErrors.new(context.errors.messages), context.errors.to_a.to_s
      end

      result = bodhi_context.connection.post do |request|
        request.url "/#{bodhi_context.namespace}/types"
        request.headers['Content-Type'] = 'application/json'
        request.headers[bodhi_context.credentials_header] = bodhi_context.credentials
        request.body = attributes.to_json
      end

      if result.status != 201
        raise Bodhi::ApiErrors.new(body: result.body, status: result.status), "status: #{result.status}, body: #{result.body}"
      end

      if result.headers['location']
        @sys_id = result.headers['location'].match(/types\/(?<name>[a-zA-Z0-9]+)/)[:name]
      end

      return nil
    end

    # DELETE a +Bodhi::Type+ from the HotSchedules IoT Platform.
    #
    # Equivalent CURL command:
    #   curl -u username:password -X DELETE https://{server}/{namespace}/types/{type.name}
    #
    # @raise [RuntimeError] if the {#bodhi_context} attribute is nil
    # @raise [Bodhi::ContextErrors] if the {#bodhi_context} attribute is not valid
    # @raise [Bodhi::ApiErrors] if the HTTP response status is NOT 204
    # @return [nil]
    # @example
    #   type = Bodhi::Type.new(
    #     bodhi_context: context,
    #     name: "MyType",
    #     properties: {
    #       name: { type: "String" },
    #       age: { type: "Integer" }
    #     }
    #   )
    #
    #   type.save!
    #   type.delete!
    def delete!
      if bodhi_context.nil?
        raise RuntimeError.new("Missing attribute #bodhi_context.  Unable to send HTTP request")
      elsif bodhi_context.invalid?
        raise Bodhi::ContextErrors.new(context.errors.messages), context.errors.to_a.to_s
      end

      result = bodhi_context.connection.delete do |request|
        request.url "/#{bodhi_context.namespace}/types/#{name}"
        request.headers[bodhi_context.credentials_header] = bodhi_context.credentials
      end

      if result.status != 204
        raise Bodhi::ApiErrors.new(body: result.body, status: result.status), "status: #{result.status}, body: #{result.body}"
      end

      return nil
    end

    # PATCH a +Bodhi::Type+ with an Array of patch operations
    #
    # Equivalent CURL command:
    #   curl -u username:password -X PATCH -H "Content-Type: application/json" \
    #     https://{server}/{namespace}/types/{type.name} \
    #     -d '[{operation1}, {operation2}, ...]'
    #
    # @note This method does not update the calling object!  Only the record on the API will be changed
    # @todo After patch is successful, update the object with the changes.
    # @param params [Array<Hash>] An array of hashes with the keys: +op+, +path+, & +value+
    # @raise [RuntimeError] if the {#bodhi_context} attribute is nil
    # @raise [Bodhi::ContextErrors] if the {#bodhi_context} attribute is not valid
    # @raise [Bodhi::ApiErrors] if the response status is NOT +204+
    # @return [nil]
    # @example
    #   type.patch!([
    #     {op: "add", path: "/properties/birthday", value: { type: "DateTime" }},
    #     {op: "add", path: "/indexes/-", value: { keys: ["birthday"] }},
    #     {op: "remove", path: "/properties/age"}
    #   ])
    def patch!(params)
      if bodhi_context.nil?
        raise RuntimeError.new("Missing attribute #bodhi_context.  Unable to send HTTP request")
      elsif bodhi_context.invalid?
        raise Bodhi::ContextErrors.new(context.errors.messages), context.errors.to_a.to_s
      end

      result = bodhi_context.connection.patch do |request|
        request.url "/#{bodhi_context.namespace}/types/#{name}"
        request.headers['Content-Type'] = 'application/json'
        request.headers[bodhi_context.credentials_header] = bodhi_context.credentials
        request.body = params.to_json
      end

      if result.status != 204
        raise Bodhi::ApiErrors.new(body: result.body, status: result.status), "status: #{result.status}, body: #{result.body}"
      end

      return nil
    end

    # PUT a +Bodhi::Type+ using the properties in the given +params+
    #
    # @todo Break this method apart into #update! (raise error) and #update (return Boolean) methods
    # @param params [Bodhi::Type, Hash, JSON String] the properties & values to update the type with
    # @raise [RuntimeError] if the {#bodhi_context} attribute is nil
    # @raise [Bodhi::ContextErrors] if the {#bodhi_context} attribute is not valid
    # @raise [Bodhi::ApiErrors] if the HTTP response status is NOT 204
    # @return [Boolean]
    # @example
    #   type = Bodhi::Type.new(bodhi_context: context, name: "MyType", properties: { name: { type: "String" }, age: { type: "Integer" } })
    #   type.save!
    #   type.update!(name: "MyType", properties: { name: { type: "String" }, age: { type: "Integer" } }, indexes: [{ keys: ["age"] }])
    def update!(params)
      if bodhi_context.nil?
        raise RuntimeError.new("Missing attribute #bodhi_context.  Unable to send HTTP request")
      elsif bodhi_context.invalid?
        raise Bodhi::ContextErrors.new(context.errors.messages), context.errors.to_a.to_s
      end

      update_attributes(params)

      if invalid?
        return false
      end

      result = bodhi_context.connection.put do |request|
        request.url "/#{bodhi_context.namespace}/types/#{name}"
        request.headers['Content-Type'] = 'application/json'
        request.headers[bodhi_context.credentials_header] = bodhi_context.credentials
        request.body = attributes.to_json
      end

      if result.status != 204
        raise Bodhi::ApiErrors.new(body: result.body, status: result.status), "status: #{result.status}, body: #{result.body}"
      end

      true
    end
    alias :update :update!

    # Queries the Bodhi API for the given +type_name+ and returns a single +Bodhi::Type+ or raises an error.
    #
    # @param context [Bodhi::Context]
    # @param type_name [String]
    # @raise [Bodhi::ContextErrors] if the provided Bodhi::Context is invalid
    # @raise [Bodhi::ApiErrors] if the HTTP response status is NOT 200
    # @return [Bodhi::Type]
    # @example
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

      type = Bodhi::Type.new(result.body)
      type.bodhi_context = context
      type
    end

    # Queries the Bodhi API for all types within the given +context+ and
    # returns an array of +Bodhi::Type+ objects
    #
    # @note This method will query ALL type records within the context and is not limited to the default 100 record limit for queries.  YE BE WARNED!
    # @param context [Bodhi::Context]
    # @return [Array<Bodhi::Type>] all Bodhi::Type records within the given context
    # @raise [Bodhi::ContextErrors] if the provided Bodhi::Context is invalid
    # @raise [Bodhi::ApiErrors] if the HTTP response status is NOT 200
    # @example
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
        records = result.body
        all_records << records
      end while records.size == 100

      all_records.flatten.collect do |type|
        record = Bodhi::Type.new(type)
        record.bodhi_context = context
        record
      end
    end

    # Search for +Bodhi::Type+ records using MongoDB query operators.
    #
    # @note This method will NOT return more than 100 records at a time!
    # @param query [Hash, JSON String] The MongoDB query to use for the search
    # @return [Bodhi::Query<Bodhi::Type>] A query object for +Bodhi::Types+ using the given +query+
    # @example
    #   query_obj = Bodhi::Type.where(name: "MyType")
    #   query_obj.from(context).all #=> [#<Bodhi::Type:0x007fbff403e808 @name="MyType">]
    #
    #   json = '{"name":{ "$in": ["MyType", "MyType2"] }}'
    #   query_obj = Bodhi::Type.where(json)
    #   query_obj.from(context).all #=> [#<Bodhi::Type:0x007fbff403e808 @name="MyType">, #<Bodhi::Type:0x007fbff403e808 @name="MyType2">]
    def self.where(query)
      query_obj = Bodhi::Query.new(Bodhi::Type, "types")
      query_obj.where(query)
      query_obj
    end

    # Defines a new Ruby class using the given +Bodhi::Type+
    # and includes the {Bodhi::Resource} and ActiveModel::Model modules
    #
    # @todo Break apart creating classes and setting classes to a constant
    # @note This method uses +Object.const_set+ to create new Classes.  Old definitions will be overwritten!
    # @param type [Bodhi::Type]
    # @return [Class] the new {Bodhi::Resource}
    # @raise [ArgumentError] if the +type+ param is not a +Bodhi::Type+
    # @example
    #   type = Bodhi::Type.new({name: "TestType", properties: { foo:{ type:"String" }}})
    #   klass = Bodhi::Type.create_class_with(type)
    #   klass # => #<Class:0x007fbff403e808 @name="TestType">
    #   klass.validations # => { foo: [#<TypeValidator:0x007fbff403e808 @type="String">] }
    #   klass.factory # => #<Bodhi::Factory:0x007fbff403e808 @klass="TestType", @generators=[]>
    def self.create_class_with(type)
      unless type.is_a? Bodhi::Type
        raise ArgumentError.new("Expected #{type.class} to be a Bodhi::Type")
      end

      klass = Object.const_set(type.name, Class.new { include Bodhi::Resource, ActiveModel::Model })

      type.properties.each_pair do |attr_name, attr_properties|
        attr_properties = Bodhi::Support.symbolize_keys(attr_properties)

        # remove Sanitizers
        attr_properties.delete_if{ |key, value| [:trim, :unique, :default, :isCurrentUser, :toLower, :encrypt].include?(key) }

        # Do not add factories or validations for system properties
        unless attr_properties[:system] == true
          klass.field(attr_name, attr_properties)
        end
      end

      # add indexes to the class
      unless type.indexes.nil?
        type.indexes.each do |index|
          if index.is_a? Bodhi::TypeIndex
            klass.index index.keys, index.options
          else
            index = Bodhi::Support.symbolize_keys(index)
            klass.index index[:keys], index[:options]
          end
        end
      end

      klass
    end

  end
end

Dir[File.dirname(__FILE__) + "/types/*.rb"].each { |file| require file }
