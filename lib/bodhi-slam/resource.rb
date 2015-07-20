module Bodhi
  module Resource
    SYSTEM_ATTRIBUTES = [:bodhi_context, :sys_created_at, :sys_version, :sys_modified_at, :sys_modified_by,
      :sys_namespace, :sys_created_by, :sys_type_version, :sys_id, :sys_embeddedType]
    attr_accessor *SYSTEM_ATTRIBUTES

    module ClassMethods
      def factory; @factory; end

      # Saves a batch of resources to the Bodhi Cloud in the given +context+
      # Returns an array of JSON objects describing the results for each record in the batch
      # 
      #   context = Bodhi::Context.new
      #   list = Resource.factory.build_list(10)
      #   Resource.save_batch(context, list)
      def save_batch(context, objects)
        if context.invalid?
          raise Bodhi::ContextErrors.new(context.errors.messages), context.errors.to_a.to_s
        end

        result = context.connection.post do |request|
          request.url "/#{context.namespace}/resources/#{name}"
          request.headers['Content-Type'] = 'application/json'
          request.headers[context.credentials_header] = context.credentials
          request.body = objects.to_json
        end

        if result.status != 200
          raise Bodhi::ApiErrors.new(body: result.body, status: result.status), "status: #{result.status}, body: #{result.body}"
        end

        objects
      end

      # Returns a single resource from the Bodhi Cloud that matches the given +id+
      # 
      #   context = Bodhi::Context.new
      #   id = Resource.factory.create(context).sys_id
      #   obj = Resource.find(context, id)
      def find(context, id)
        if context.invalid?
          raise Bodhi::ContextErrors.new(context.errors.messages), context.errors.to_a.to_s
        end

        unless id.is_a? String
          raise ArgumentError.new("Expected 'id' to be a String. 'id' #=> #{id.class}")
        end

        result = context.connection.get do |request|
          request.url "/#{context.namespace}/resources/#{name}/#{id}"
          request.headers[context.credentials_header] = context.credentials
        end

        if result.status != 200
          raise Bodhi::ApiErrors.new(body: result.body, status: result.status), "status: #{result.status}, body: #{result.body}"
        end

        resource_attributes = JSON.parse(result.body)
        factory.build(context, resource_attributes)
      end

      # Returns all records of the given resource from the Bodhi Cloud.
      # 
      #   context = Bodhi::Context.new
      #   Resource.find_all(context) # => [#<Resource:0x007fbff403e808>, #<Resource:0x007fbff403e808>, ...]
      def find_all(context)
        if context.invalid?
          raise Bodhi::ContextErrors.new(context.errors.messages), context.errors.to_a.to_s
        end

        page = 1
        records = []

        begin
          result = context.connection.get do |request|
            request.url "/#{context.namespace}/resources/#{name}?paging=page:#{page}"
            request.headers[context.credentials_header] = context.credentials
          end

          if result.status != 200
            raise Bodhi::ApiErrors.new(body: result.body, status: result.status), "status: #{result.status}, body: #{result.body}"
          end

          page += 1
          records << JSON.parse(result.body)
        end while records.size == 100

        records.flatten.collect{ |record| factory.build(record) }
      end

      # Aggregates the given resource based on the supplied +pipeline+
      # 
      #   context = Bodhi::Context.new
      #   Resource.aggregate(context, "[{ $match: { property: { $gte: 20 }}}]")
      def aggregate(context, pipeline)
        if context.invalid?
          raise Bodhi::ContextErrors.new(context.errors.messages), context.errors.to_a.to_s
        end

        unless pipeline.is_a? String
          raise ArgumentError.new("Expected 'pipeline' to be a String. 'pipeline' #=> #{pipeline.class}")
        end

        result = context.connection.get do |request|
          request.url "/#{context.namespace}/resources/#{name}/aggregate?pipeline=#{pipeline}"
          request.headers[context.credentials_header] = context.credentials
        end

        if result.status != 200
          raise Bodhi::ApiErrors.new(body: result.body, status: result.status), "status: #{result.status}, body: #{result.body}"
        end

        JSON.parse(result.body)
      end

      # Returns all records for a resource which match the given +query+
      # 
      #   context = Bodhi::Context.new
      #   Resource.where(context, "{property: 'value'}")
      def where(context, query)
        if context.invalid?
          raise Bodhi::ContextErrors.new(context.errors.messages), context.errors.to_a.to_s
        end

        unless query.is_a? String
          raise ArgumentError.new("Expected 'query' to be a String. 'query' #=> #{query.class}")
        end

        result = context.connection.get do |request|
          request.url "/#{context.namespace}/resources/#{name}?where=#{query}"
          request.headers[context.credentials_header] = context.credentials
        end

        if result.status != 200
          raise Bodhi::ApiErrors.new(body: result.body, status: result.status), "status: #{result.status}, body: #{result.body}"
        end

        resources = JSON.parse(result.body)
        resources.map{ |attributes| factory.build(context, attributes) }
      end

      # Deletes all records from a resource in the given +context+
      # 
      #   context = Bodhi::Context.new
      #   Resource.delete_all(context)
      def delete_all(context)
        if context.invalid?
          raise Bodhi::ContextErrors.new(context.errors.messages), context.errors.to_a.to_s
        end

        result = context.connection.delete do |request|
          request.url "/#{context.namespace}/resources/#{name}"
          request.headers[context.credentials_header] = context.credentials
        end

        if result.status != 204
          raise Bodhi::ApiErrors.new(body: result.body, status: result.status), "status: #{result.status}, body: #{result.body}"
        end
      end
    end

    module InstanceMethods
      # Returns a Hash of the Objects form attributes
      # 
      #   s = SomeResource.build({foo:"test", bar:12345})
      #   s.attributes # => { foo: "test", bar: 12345 }
      def attributes
        attributes = Hash.new
        self.instance_variables.each do |variable|
          attribute_name = variable.to_s.delete('@').to_sym
          attributes[attribute_name] = send(attribute_name) unless SYSTEM_ATTRIBUTES.include?(attribute_name)
        end
        attributes
      end
  
      # Returns all the Objects attributes as JSON.
      # It converts any nested Objects to JSON if they respond to +to_json+
      # 
      #   s = SomeResource.build({foo:"test", bar:12345})
      #   s.to_json # => { "foo":"test", "bar":12345 }
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
          request.url "/#{bodhi_context.namespace}/resources/#{self.class}"
          request.headers['Content-Type'] = 'application/json'
          request.headers[bodhi_context.credentials_header] = bodhi_context.credentials
          request.body = attributes.to_json
        end
  
        if result.status != 201
          raise Bodhi::ApiErrors.new(body: result.body, status: result.status), "status: #{result.status}, body: #{result.body}"
        end

        if result.headers['location']
          @sys_id = result.headers['location'].match(/(?<id>[a-zA-Z0-9]{24})/)[:id]
        end
      end

      def delete!
        result = bodhi_context.connection.delete do |request|
          request.url "/#{bodhi_context.namespace}/resources/#{self.class}/#{sys_id}"
          request.headers[bodhi_context.credentials_header] = bodhi_context.credentials
        end
  
        if result.status != 204
          raise Bodhi::ApiErrors.new(body: result.body, status: result.status), "status: #{result.status}, body: #{result.body}"
        end
      end

      def patch!(params)
        result = bodhi_context.connection.patch do |request|
          request.url "/#{bodhi_context.namespace}/resources/#{self.class}/#{sys_id}"
          request.headers['Content-Type'] = 'application/json'
          request.headers[bodhi_context.credentials_header] = bodhi_context.credentials
          request.body = params
        end
  
        if result.status != 204
          raise Bodhi::ApiErrors.new(body: result.body, status: result.status), "status: #{result.status}, body: #{result.body}"
        end
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods, Bodhi::Validations)
      base.instance_variable_set(:@factory, Bodhi::Factory.new(base))
    end
  end
end