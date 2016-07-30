module Bodhi
  # Interface for interacting with resources on the HotSchedules IoT Platform.
  module Resource

    # The API context that binds a +Bodhi::Resource+ instance to the HotSchedules IoT Platform
    # @note This is required for the all instance methods to work correctly
    # @return [Bodhi::Context] the API context linked to this object
    attr_accessor :bodhi_context

    module ClassMethods

      # Sets the resources embedded status to either true/false.
      #
      # @param bool [Boolean]
      # @return [Boolean]
      def embedded(status); @embedded = status; end

      # Checks if the resource is embedded
      #
      # @return [Boolean]
      def is_embedded?; @embedded; end

      # Defines the given +name+ and +options+ as a form attribute for the class.
      # The +name+ is set as a property, and validations & factory generators
      # are added based on the supplied +options+
      #
      # @param name [String]
      # @param options [Hash]
      # @example
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

      # Generates a new {Bodhi::Type} instance using the classes metadata
      #
      # @return [Bodhi::Type]
      # @example
      #   class User
      #     include Bodhi::Resource
      #
      #     field :first_name, type: "String", required: true, is_not_blank: true
      #     field :last_name, type: "String", required: true, is_not_blank: true
      #     field :email, type: "String", required: true, is_not_blank: true, is_email: true
      #
      #     index ["last_name"]
      #   end
      #
      #   User.build_type #=> #<Bodhi::Type:0x007fbff403e808 @name="User" @properties={...} @indexes=[...]>
      def build_type
        Bodhi::Type.new(name: self.name, properties: self.properties, indexes: self.indexes, embedded: self.is_embedded?)
      end

      # Saves a batch of resources to the Bodhi Cloud in the given +context+
      # Returns an array of JSON objects describing the results for each record in the batch
      #
      # @deprecated This uses the old bulk upload process and will be removed in version 1.0.0  DO NOT USE!
      # @example
      #   context = Bodhi::Context.new
      #   list = Resource.factory.build_list(10)
      #   Resource.save_batch(context, list)
      def save_batch(context, objects)
        batch = Bodhi::ResourceBatch.new(name, objects)
        batch.save!(context)
        batch
      end

      # Counts all records that match the given +query+
      #
      # Equivalent CURL command:
      #   curl -u {username}:{password} https://{server}/{namespace}/resources/{resource}/count?where={query}
      # @param context [Bodhi::Context]
      # @param query [Hash] MongoDB query operations
      # @example
      #   Resource.count(context) #=> # count all records
      #   Resource.count(context, name: "Foo") #=> # count all records with name == "Foo"
      def count(context, query={})
        query_obj = Bodhi::Query.new(name)
        query_obj.where(query).from(context)
        query_obj.count
      end

      # Deletes all records that match the given +query+
      #
      # Equivalent CURL command:
      #   curl -u {username}:{password} -X DELETE https://{server}/{namespace}/resources/{resource}?where={query}
      # @note Beware: It's easy to delete an entire collection with this method!  Use it wisely :)
      # @param context [Bodhi::Context]
      # @param query [Hash] MongoDB query operations
      # @return [Hash] with key: +count+
      # @todo add more query complex examples
      # @example
      #   # delete with a query
      #   Resource.delete!(context, sys_created_at: { '$lte': 6.months.ago.iso8601 })
      #
      #   # delete all records
      #   Resource.delete!(context)
      def delete!(context, query={})
        query_obj = Bodhi::Query.new(name)
        query_obj.where(query).from(context)
        query_obj.delete
      end

      # Creates a new resource with the given +properties+
      # and POSTs it to the IoT Platform
      #
      # Equivalent CURL command:
      #   curl -u {username}:{password} -X POST -H "Content-Type: application/json" \
      #   https://{server}/{namespace}/resources/{resource} \
      #   -d '{properties}'
      # @param context [Bodhi::Context]
      # @param properties [Hash]
      # @return [Bodhi::Resource]
      # @raise [Bodhi::ContextErrors] if the given +Bodhi::Context+ is invalid
      # @raise [Bodhi::ApiErrors] if the record cannot be saved
      #   Resource.create!(context, name: "Foo", age: 125, tags: ["green", "blue"])
      def create!(context, properties)
        if context.invalid?
          raise Bodhi::ContextErrors.new(context.errors.messages), context.errors.to_a.to_s
        end

        # Build a new record and set the context
        record = self.new(properties)
        record.bodhi_context = context

        # POST to the IoT Platform
        record.save!
        return record
      end

      # Search for a record with the given +id+
      #
      # Equivalent CURL command:
      #   curl -u {username}:{password} https://{server}/{namespace}/resources/{resource}/{id}
      # @param id [String] the {Bodhi::Properties#sys_id} of the record
      # @param context [Bodhi::Context]
      # @return [Bodhi::Resource]
      # @raise [Bodhi::ContextErrors] if the given +Bodhi::Context+ is invalid
      # @raise [Bodhi::ApiErrors] if response status is NOT +200+
      # @raise [ArgumentError] if the given +id+ is NOT a +String+
      # @example
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

      # Returns all records in the given +context+
      #
      # All records returned by this method will have their
      # {#bodhi_context} attribute set to +context+
      #
      # Pseudo-code & CURL command:
      #   do
      #     curl -u {username}:{password} https://{server}/{namespace}/resources/{resource}?paging=page:{page}
      #     page ++
      #   while {response.body.count} == 100
      # @note This method will return ALL records!!  Don't use on large collections!  YE BE WARNED!!
      # @param context [Bodhi::Context]
      # @return [Array<Bodhi::Resource>]
      # @raise [Bodhi::ContextErrors] if the given +context+ is invalid
      # @raise [Bodhi::ApiErrors] if any response status is NOT 200
      # @example
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
        end until result.body.size != 100

        records.flatten.collect{ |record| Object.const_get(name).new(record.merge(bodhi_context: context)) }
      end
      alias :all :find_all

      # Performs MongoDB aggregations using the given +pipeline+
      #
      # Equivalent CURL command:
      #   curl -u {username}:{password} https://{server}/{namespace}/resources/{resource}/aggregate?pipeline={pipeline}
      # @note Large aggregations can be very time and resource intensive!
      # @param context [Bodhi::Context]
      # @param pipeline [String]
      # @return [Hash] the JSON response converted to a Ruby Hash
      # @raise [ArgumentError] if the given +pipeline+ is NOT a +String+
      # @raise [Bodhi::ContextErrors] if the given +context+ is invalid
      # @raise [Bodhi::ApiErrors] if any response status is NOT +200+
      # @example
      #   Resource.aggregate(context, "[{ $match: { age: { $gte: 21 }}}]")
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

      # Returns a {Bodhi::Query} object with the given +query+
      #
      # @param query [Hash] the MongoDB query operations
      # @return [Bodhi::Query<Bodhi::Resource>] a {Bodhi::Query} object, bound to the {Bodhi::Resource} with the given +query+
      # @example
      #   context = Bodhi::Context.new
      #   Resource.where({conditions}).from(context).all
      #   Resource.where({conditions}).and({more conditions}).limit(10).from(context).all
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
