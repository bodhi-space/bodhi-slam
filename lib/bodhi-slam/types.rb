module Bodhi
  class Type
    include Bodhi::Factories
    include Bodhi::Properties
    include Bodhi::Validations

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

    generates :extends, type: "String", matches: "[a-zA-Z_-]{10,20}"
    generates :name, type: "String", required: true, is_not_blank: true
    generates :namespace, type: "String", required: true
    generates :properties, type: "Object", required: true
    generates :package, type: "String"
    generates :embedded, type: "Boolean"
    generates :version, type: "String"

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

      if result.headers['location']
        @sys_id = result.headers['location'].match(/types\/(?<name>[a-zA-Z0-9]+)/)[:name]
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

      type = Bodhi::Type.new(result.body)
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
        records = result.body
        all_records << records
      end while records.size == 100

      all_records.flatten.collect do |type|
        record = Bodhi::Type.new(type)
        record.bodhi_context = context
        record
      end
    end

    def self.where(query)
      query_obj = Bodhi::Query.new(Bodhi::Type, "types")
      query_obj.where(query)
      query_obj
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

      klass = Object.const_set(type.name, Class.new { include Bodhi::Resource })

      type.properties.each_pair do |attr_name, attr_properties|
        # symbolize the attr_properties keys
        attr_properties = attr_properties.reduce({}) do |memo, (k, v)|
          memo.merge({ k.to_sym => v})
        end

        # remove Sanitizers
        attr_properties.delete_if{ |key, value| [:trim, :unique, :default, :isCurrentUser, :toLower].include?(key) }

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
            # index is a raw json object
            # symbolize the index option keys
            index = index.reduce({}) do |memo, (k, v)|
              memo.merge({ k.to_sym => v})
            end

            klass.index index[:keys], index[:options]
          end
        end
      end

      klass
    end

  end
end

Dir[File.dirname(__FILE__) + "/types/*.rb"].each { |file| require file }