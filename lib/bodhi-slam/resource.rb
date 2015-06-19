module Bodhi
  module Resource
    SYSTEM_ATTRIBUTES = [:bodhi_context, :sys_created_at, :sys_version, :sys_modified_at, :sys_modified_by,
      :sys_namespace, :sys_created_by, :sys_type_version, :sys_id]
    attr_accessor *SYSTEM_ATTRIBUTES

    module ClassMethods
      def build(context, params={})
        params.merge!({bodhi_context: context})
        FactoryGirl.build(name, params)
      end

      def build_list(context, amount, params={})
        params.merge!({bodhi_context: context})
        FactoryGirl.build_list(name, amount, params)
      end

      def create(context, params={})
        params.merge!({bodhi_context: context})
        FactoryGirl.create(name, params)
      end

      def create_list(context, amount, params={})
        params.merge!({bodhi_context: context})
        records = FactoryGirl.build_list(name, amount, params)
        result = context.connection.post do |request|
          request.url "/#{context.namespace}/resources/#{name}"
          request.headers['Content-Type'] = 'application/json'
          request.headers[context.credentials_header] = context.credentials
          request.body = records.to_json
        end

        puts "\033[33mResult Body\033[0m: #{result.body}"

        if result.status != 200
          errors = JSON.parse result.body
          errors.each{|error| error['status'] = result.status } if errors.is_a? Array
          errors["status"] = result.status if errors.is_a? Hash
          raise errors.to_s
        end

        puts "\033[33mRecords\033[0m: #{records.map(&:attributes)}"

        records
      end

      def find(context, id)
        raise context.errors unless context.valid?
        raise ArgumentError.new("Expected 'id' to be a String. 'id' #=> #{id.class}") unless id.is_a? String

        result = context.connection.get do |request|
          request.url "/#{context.namespace}/resources/#{name}/#{id}"
          request.headers[context.credentials_header] = context.credentials
        end

        if result.status != 200
          errors = JSON.parse result.body
          errors.each{|error| error['status'] = result.status } if errors.is_a? Array
          errors["status"] = result.status if errors.is_a? Hash
          raise errors.to_s
        end

        resource_attributes = JSON.parse(result.body)
        self.build(context, resource_attributes)
      end

      def delete_all(context)
        raise context.errors unless context.valid?

        result = context.connection.delete do |request|
          request.url "/#{context.namespace}/resources/#{name}"
          request.headers[context.credentials_header] = context.credentials
        end

        if result.status != 204
          errors = JSON.parse result.body
          errors.each{|error| error['status'] = result.status } if errors.is_a? Array
          errors["status"] = result.status if errors.is_a? Hash
          raise errors.to_s
        end
      end
    end

    module InstanceMethods
      # Returns a Hash of the Objects form attributes
      # 
      # s = SomeResource.build({foo:"test", bar:12345})
      # s.attributes # => { foo: "test", bar: 12345 }
      def attributes
        attributes = Hash.new
        self.instance_variables.each do |variable|
          attribute_name = variable.to_s.delete('@').to_sym
          attributes[attribute_name] = send(attribute_name) unless SYSTEM_ATTRIBUTES.include?(attribute_name)
        end
        attributes
      end
  
      # Returns all the Objects attributes as JSON.
      # Will convert any nested Objects to JSON if they respond to :to_json
      # 
      # s = SomeResource.build({foo:"test", bar:12345})
      # s.to_json # => { "foo":"test", "bar":12345 }
      def to_json(base=nil)
        super if base
        attributes.to_json
      end

      def save!
        result = bodhi_context.connection.post do |request|
          request.url "/#{bodhi_context.namespace}/resources/#{self.class}"
          request.headers['Content-Type'] = 'application/json'
          request.headers[bodhi_context.credentials_header] = bodhi_context.credentials
          request.body = attributes.to_json
        end
  
        if result.status != 201
          errors = JSON.parse result.body
          errors.each{|error| error['status'] = result.status } if errors.is_a? Array
          errors["status"] = result.status if errors.is_a? Hash
          raise errors.to_s
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
          errors = JSON.parse result.body
          errors.each{|error| error['status'] = result.status } if errors.is_a? Array
          errors["status"] = result.status if errors.is_a? Hash
          raise errors.to_s
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
          errors = JSON.parse result.body
          errors.each{|error| error['status'] = result.status } if errors.is_a? Array
          errors["status"] = result.status if errors.is_a? Hash
          raise errors.to_s
        end
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods, Bodhi::Validations)
    end
  end
end