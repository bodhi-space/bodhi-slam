module Bodhi
  module Resource

    attr_accessor :bodhi_context

    module ClassMethods

      def embedded(bool); @embedded = bool; end
      def is_embedded?; @embedded; end

      # Defines the given +name+ and +options+ as a form attribute for the class.
      # The +name+ is set as a property, and validations & factory generators are added based on the supplied +options+
      # 
      #   class User
      #     include Bodhi::Resource
      #
      #     field :first_name, type: "String", required: true, is_not_blank: true
      #     field :last_name, type: "String", required: true, is_not_blank: true
      #     field :email, type: "String", required: true, is_not_blank: true, is_email: true
      #   end
      #
      #   object = User.new(first_name: "John", last_name: "Smith", email: "jsmith@email.com")
      #   object.to_json #=> { "first_name": "John", "last_name": "Smith", "email": "jsmith@email.com" }
      def field(name, options)
        property(name.to_sym, options)
        validates(name.to_sym, options)
        generates(name.to_sym, options)
      end

      def build_type
        Bodhi::Type.new(name: self.name, properties: self.properties, indexes: self.indexes, embedded: self.is_embedded?)
      end

      # Saves a batch of resources to the Bodhi Cloud in the given +context+
      # Returns an array of JSON objects describing the results for each record in the batch
      # 
      #   context = Bodhi::Context.new
      #   list = Resource.factory.build_list(10)
      #   Resource.save_batch(context, list)
      def save_batch(context, objects)
        batch = Bodhi::ResourceBatch.new(name, objects)
        batch.save!(context)
        batch
      end

      # Counts all records that match the given query
      #
      #   context = Bodhi::Context.new
      #   count = Resource.count(context, name: "Foo")
      def count(context, query={})
        query_obj = Bodhi::Query.new(name)
        query_obj.where(query).from(context)
        query_obj.count
      end

      # Deletes all records that match the given query
      #
      #   context = Bodhi::Context.new
      #   count = Resource.delete(context, name: "Foo")
      def delete!(context, query={})
        query_obj = Bodhi::Query.new(name)
        query_obj.where(query).from(context)
        query_obj.delete
      end

      def create!(params, context=nil)
        if context.nil?
          context = Bodhi::Context.global_context
        end

        if context.invalid?
          raise Bodhi::ContextErrors.new(context.errors.messages), context.errors.to_a.to_s
        end

        record = self.new(params)
        record.bodhi_context = context
        record.save!
        return record
      end

      # Returns a single resource from the Bodhi Cloud that matches the given +id+
      # 
      #   context = Bodhi::Context.new
      #   id = Resource.factory.create(context).sys_id
      #   obj = Resource.find(context, id)
      def find(id, context=nil)
        if context.nil?
          context = Bodhi::Context.global_context
        end

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

        record = Object.const_get(name).new(result.body)
        record.bodhi_context = context
        record
      end

      # Returns all records of the given resource from the Bodhi Cloud.
      # 
      #   context = Bodhi::Context.new
      #   Resource.find_all(context) # => [#<Resource:0x007fbff403e808>, #<Resource:0x007fbff403e808>, ...]
      def find_all(context=nil)
        if context.nil?
          context = Bodhi::Context.global_context
        end

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
          records << result.body
        end while records.size == 100

        records.flatten.collect{ |record| Object.const_get(name).new(record.merge(bodhi_context: context)) }
      end
      alias :all :find_all

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

        result.body
      end

      # Returns a Bodhi::Query object for quering the given Resource
      # 
      #   context = Bodhi::Context.new
      #   Resource.where("{property: 'value'}").from(context).all
      #   Resource.where("{conditions}").and("{more conditions}").limit(10).from(context).all
      def where(query)
        query_obj = Bodhi::Query.new(name)
        query_obj.where(query)
        query_obj
      end
    end

    module InstanceMethods
      # Saves the resource to the Bodhi Cloud.  Returns true if record was saved
      # 
      #   obj = Resource.new
      #   obj.save # => true
      #   obj.persisted? # => true
      def save
        if invalid?
          return false
        end

        if bodhi_context.nil?
          @bodhi_context = Bodhi::Context.global_context
        end

        if bodhi_context.invalid?
          raise Bodhi::ContextErrors.new(bodhi_context.errors.messages), bodhi_context.errors.to_a.to_s
        end

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

        true
      end

      # Saves the resource to the Bodhi Cloud.  Raises ArgumentError if record could not be saved.
      # 
      #   obj = Resouce.new
      #   obj.save!
      #   obj.persisted? # => true
      def save!
        if bodhi_context.invalid?
          raise Bodhi::ContextErrors.new(bodhi_context.errors.messages), bodhi_context.errors.to_a.to_s
        end

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
      alias :destroy :delete!

      def update!(params)
        update_attributes(params)

        if invalid?
          return false
        end

        result = bodhi_context.connection.put do |request|
          request.url "/#{bodhi_context.namespace}/resources/#{self.class}/#{sys_id}"
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

      def upsert!(params={})
        update_attributes(params)

        if invalid?
          return false
        end

        result = bodhi_context.connection.put do |request|
          request.url "/#{bodhi_context.namespace}/resources/#{self.class}?upsert=true"
          request.headers['Content-Type'] = 'application/json'
          request.headers[bodhi_context.credentials_header] = bodhi_context.credentials
          request.body = attributes.to_json
        end

        unless [204, 201].include?(result.status)
          raise Bodhi::ApiErrors.new(body: result.body, status: result.status), "status: #{result.status}, body: #{result.body}"
        end

        if result.headers['location']
          @sys_id = result.headers['location'].match(/(?<id>[a-zA-Z0-9]{24})/)[:id]
        end
      end
      alias :upsert :upsert!

      def patch!(params)
        result = bodhi_context.connection.patch do |request|
          request.url "/#{bodhi_context.namespace}/resources/#{self.class}/#{sys_id}"
          request.headers['Content-Type'] = 'application/json'
          request.headers[bodhi_context.credentials_header] = bodhi_context.credentials
          request.body = params.to_json
        end
  
        if result.status != 204
          raise Bodhi::ApiErrors.new(body: result.body, status: result.status), "status: #{result.status}, body: #{result.body}"
        end
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods, Bodhi::Properties, Bodhi::Associations, Bodhi::Validations, Bodhi::Indexes, Bodhi::Factories)
      base.instance_variable_set(:@embedded, false)
    end
  end
end