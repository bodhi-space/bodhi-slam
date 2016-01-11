module Bodhi
  class Query
    attr_reader :klass, :controller, :url, :context, :criteria, :fields, :paging, :sorting

    def initialize(klass, controller="resources")
      @controller = controller
      @klass = Object.const_get(klass.to_s)
      @criteria = {}
      @fields = []
      @paging = {}
      @sorting = {}
    end

    def clear!
      @context = nil
      @criteria = {}
      @fields.clear
      @paging.clear
      @sorting.clear
    end

    def url
      unless context.nil?
        if @controller == "resources"
          query = "/#{context.namespace}/#{controller}/#{klass}?"
        else
          query = "/#{context.namespace}/#{controller}?"
        end
      else
        query = "/#{controller}/#{klass}?"
      end
      params = []

      unless criteria.keys.empty?
        params << "where=#{criteria.to_json}"
      end

      unless fields.empty?
        params << "fields=#{fields.join(',')}"
      end

      unless paging.empty?
        paging_params = []

        if paging[:page]
          paging_params << "page:#{paging[:page]}"
        end

        if paging[:limit]
          paging_params << "limit:#{paging[:limit]}"
        end

        params << "paging=#{paging_params.join(',')}"
      end

      unless sorting.empty?
        sort_params = []

        if sorting[:field]
          sort_params << sorting[:field]
        end

        if sorting[:order]
          sort_params << sorting[:order]
        end

        params << "sort=#{sort_params.join(':')}"
      end

      query << params.join('&')
      #query.gsub(/\s+/, "")
    end

    def count
      if context.nil?
        raise ArgumentError.new("a Bodhi::Context is required to query the API")
      end

      if context.invalid?
        raise Bodhi::ContextErrors.new(context.errors.messages), context.errors.to_a.to_s
      end

      result = context.connection.get do |request|
        request.url self.url.gsub(klass.name, "#{klass}/count")
        request.headers[context.credentials_header] = context.credentials
      end

      if result.status != 200
        raise Bodhi::ApiErrors.new(body: result.body, status: result.status), "status: #{result.status}, body: #{result.body}"
      end

      result.body["count"]
    end

    def delete
      if context.nil?
        raise ArgumentError.new("a Bodhi::Context is required to query the API")
      end

      if context.invalid?
        raise Bodhi::ContextErrors.new(context.errors.messages), context.errors.to_a.to_s
      end

      result = context.connection.delete do |request|
        request.url self.url
        request.headers[context.credentials_header] = context.credentials
      end

      if result.status != 204
        raise Bodhi::ApiErrors.new(body: result.body, status: result.status), "status: #{result.status}, body: #{result.body}"
      end

      result.body
    end

    def all
      if context.nil?
        raise ArgumentError.new("a Bodhi::Context is required to query the API")
      end

      if context.invalid?
        raise Bodhi::ContextErrors.new(context.errors.messages), context.errors.to_a.to_s
      end

      result = context.connection.get do |request|
        request.url self.url
        request.headers[context.credentials_header] = context.credentials
      end

      if result.status != 200
        raise Bodhi::ApiErrors.new(body: result.body, status: result.status), "status: #{result.status}, body: #{result.body}"
      end

      result.body.map{ |attributes| klass.new(attributes.merge(bodhi_context: context)) }
    end

    def first
      if context.nil?
        raise ArgumentError.new("a Bodhi::Context is required to query the API")
      end

      if context.invalid?
        raise Bodhi::ContextErrors.new(context.errors.messages), context.errors.to_a.to_s
      end

      result = context.connection.get do |request|
        request.url self.url
        request.headers[context.credentials_header] = context.credentials
      end

      if result.status != 200
        raise Bodhi::ApiErrors.new(body: result.body, status: result.status), "status: #{result.status}, body: #{result.body}"
      end

      result.body.map{ |attributes| klass.new(attributes.merge(bodhi_context: context)) }.first
    end

    def last
      if context.nil?
        raise ArgumentError.new("a Bodhi::Context is required to query the API")
      end

      if context.invalid?
        raise Bodhi::ContextErrors.new(context.errors.messages), context.errors.to_a.to_s
      end

      result = context.connection.get do |request|
        request.url self.url
        request.headers[context.credentials_header] = context.credentials
      end

      if result.status != 200
        raise Bodhi::ApiErrors.new(body: result.body, status: result.status), "status: #{result.status}, body: #{result.body}"
      end

      result.body.map{ |attributes| klass.new(attributes.merge(bodhi_context: context)) }.last
    end

    def from(context)
      unless context.is_a? Bodhi::Context
        raise ArgumentError.new("Expected Bodhi::Context but received #{context.class}")
      end

      @context = context
      self
    end

    def where(query)
      if query.is_a?(String)
        json = JSON.parse(query)
        query = Bodhi::Support.symbolize_keys(json)
      else
        query = Bodhi::Support.symbolize_keys(query)
      end

      @criteria.merge!(query)
      self
    end
    alias :and :where

    def select(field_names)
      unless field_names.is_a? String
        raise ArgumentError.new("Expected String but received #{field_names.class}")
      end

      fields_array = field_names.split(',')
      @fields << fields_array
      @fields.flatten!
      @fields.uniq!
      self
    end

    def limit(number)
      unless number.is_a? Integer
        raise ArgumentError.new("Expected Integer but received #{number.class}")
      end

      unless number <= 100
        raise ArgumentError.new("Expected limit to be less than or equal to 100 but received #{number}")
      end

      @paging[:limit] = number
      self
    end

    def page(number)
      unless number.is_a? Integer
        raise ArgumentError.new("Expected Integer but received #{number.class}")
      end

      @paging[:page] = number
      self
    end

    def sort(field, order=nil)
      unless field.is_a? String
        raise ArgumentError.new("Expected String but received #{field.class}")
      end

      unless order.nil?
        @sorting[:order] = order
      end

      @sorting[:field] = field
      self
    end

  end
end