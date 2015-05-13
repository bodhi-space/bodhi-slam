require "faraday"
require "factory_girl"
require "json"
require "time"

class BodhiSlam
  def self.context(params, &block)
    bodhi_context = BodhiContext.new params
    bodhi_context.validate!
    
    puts "Switching context to: #{bodhi_context.attributes}"
    
    yield bodhi_context
    
    puts "Exiting context: #{bodhi_context.attributes}"
  end
  
  def self.analyze(context)
    context.validate!

    #Get the types for this namespace
    result = context.connection.get do |request|
      request.url "/#{context.namespace}/types"
      request.headers[context.credentials_header] = context.credentials
    end
    
    if result.status != 200
      errors = JSON.parse result.body
      errors.each{|error| error['status'] = result.status } if errors.is_a? Array
      errors["status"] = result.status if errors.is_a? Hash
      raise errors.to_s
    end
    types = JSON.parse(result.body)
    
    #Get the enumerations for this namespace
    result = context.connection.get do |request|
      request.url "/#{context.namespace}/enums"
      request.headers[context.credentials_header] = context.credentials
    end
    
    if result.status != 200
      errors = JSON.parse result.body
      errors.each{|error| error['status'] = result.status } if errors.is_a? Array
      errors["status"] = result.status if errors.is_a? Hash
      raise errors.to_s
    end
    enumerations = JSON.parse(result.body)
    
    #Create a class & factory for each type
    setup_factory = lambda do |name, properties|
      FactoryGirl.define do
        factory name.to_sym do
          properties.each_pair do |k,v|
            unless v["system"]

              case v["type"]
              when "GeoJSON"
                send(k) { {type: "Point", coordinates: [10,20]} } if v["multi"].nil?
                send(k) { [*0..5].sample.times.collect{ {type: "Point", coordinates: [10,20]} } } if v["multi"]
              when "Boolean"
                send(k) { [true, false].sample } if v["multi"].nil?
                send(k) { [*0..5].sample.times.collect{ [true, false].sample } } if v["multi"]
              when "Enumerated"
                enum = enumerations.select{ |enumeration| enumeration["name"] == v["ref"].split('.')[0] }[0]
                send(k) { enum["values"].sample[v["ref"].split('.')[1]] } if v["multi"].nil?
                send(k) { [*0..5].sample.times.collect{ enum["values"].sample[v["ref"].split('.')[1]] } } if v["multi"]
              when "Object"
                send(k) { {"foo" => SecureRandom.hex} } if v["multi"].nil?
                send(k) { [*0..5].sample.times.collect{ {"foo" => SecureRandom.hex} } } if v["multi"]
              when "String"
                send(k) { SecureRandom.hex } if v["multi"].nil?
                send(k) { [*0..5].sample.times.collect{ SecureRandom.hex } } if v["multi"]
              when "DateTime"
                send(k) { Time.at(rand * Time.now.to_i).iso8601 } if v["multi"].nil?
                send(k) { [*0..5].sample.times.collect{ Time.at(rand * Time.now.to_i).iso8601 } } if v["multi"]
              when "Integer"
                send(k) { SecureRandom.random_number(100) } if v["multi"].nil?
                send(k) { [*0..5].sample.times.collect{ SecureRandom.random_number(100) } } if v["multi"]
              when "Real"
                send(k) { SecureRandom.random_number } if v["multi"].nil?
                send(k) { [*0..5].sample.times.collect{ SecureRandom.random_number } } if v["multi"]
              else # Its an embedded type
                send(k) { FactoryGirl.build(v["type"]).attributes } if v["multi"].nil?
                send(k) { [*0..5].sample.times.collect{ FactoryGirl.build(v["type"]).attributes } } if v["multi"]
              end
              
            end
          end
        end
      end
    end
    
    create_type = lambda do |type|
      if type["package"] != "system"
        properties = type["properties"].keys.collect{ |key| key.to_sym }
        klass = Object.const_set(type["name"], Class.new {
          include BodhiResource
          attr_accessor *properties
        })
        klass.define_singleton_method(:find) do |id, context|
          result = context.connection.get do |request|
            request.url "/#{context.namespace}/resources/#{klass.name}/#{id}"
            request.headers[context.credentials_header] = context.credentials
          end
  
          if result.status != 200
            errors = JSON.parse result.body
            errors.each{|error| error['status'] = result.status } if errors.is_a? Array
            errors["status"] = result.status if errors.is_a? Hash
            raise errors.to_s
          end
  
          object_hash = JSON.parse(result.body)
          object_hash["bodhi_context"] = context
          return FactoryGirl.build(klass.name, object_hash)
        end

        setup_factory.call(klass.name, type["properties"]) unless FactoryGirl.factories.registered?(klass.name)
        puts "Created Class & Factory for: #{klass.name}"
      end
    end
    
    embedded_types = types.select{ |type| type["embedded"] }
    normal_types = types.select{ |type| !type["embedded"] }
    
    embedded_types.each{ |type| create_type.call(type) }
    normal_types.each{ |type| create_type.call(type) }
    
    #Party!
  end
end


class BodhiContext
  attr_reader :connection, :server, :namespace, 
    :credentials, :credentials_type, :credentials_header

  def initialize(params)
    params.symbolize_keys!
    
    @connection = Faraday.new(url: params[:server]) do |faraday|
      faraday.request  :url_encoded             # form-encode POST params
      #faraday.response :logger                  # log requests to STDOUT
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    end
    @server = params[:server]
    @namespace = params[:namespace]
    
    if params[:cookie]
      @credentials = params[:cookie]
      @credentials_header = "Cookie"
      @credentials_type = "HTTP_COOKIE"
    else
      @credentials = @connection.basic_auth params[:username], params[:password]
      @credentials_header = "Authorization"
      @credentials_type = "HTTP_BASIC"
    end
  end
  
  def attributes
    attributes = Hash.new
    self.instance_variables.each do |variable|
      attribute_name = variable.to_s.delete('@').to_sym
      attributes[attribute_name] = send(attribute_name) unless [:connection, :credentials_header].include?(attribute_name)
    end
    attributes
  end
  
  def validate!
    raise ArgumentError, "Server URL must be a String" unless server.is_a?(String)
    raise ArgumentError, "Namespace name must be a String" unless namespace.is_a?(String)
  end
end


module BodhiResource
  SYSTEM_ATTRIBUTES = [:bodhi_context, :sys_created_at, :sys_version, :sys_modified_at, :sys_modified_by,
    :sys_namespace, :sys_created_by, :sys_type_version, :sys_id]
  attr_accessor *SYSTEM_ATTRIBUTES
  
  # - Returns a Hash of the Objects form attributes
  def attributes
    attributes = Hash.new
    self.instance_variables.each do |variable|
      attribute_name = variable.to_s.delete('@').to_sym
      attributes[attribute_name] = send(attribute_name) unless SYSTEM_ATTRIBUTES.include?(attribute_name)
    end
    attributes
  end
  
  # - Converts all the Objects attributes to JSON
  def to_json
    attributes = Hash.new
    self.instance_variables.each do |variable|
      attribute_name = variable.to_s.delete('@').to_sym
      attributes[attribute_name] = send(attribute_name)
    end
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
      @sys_id = result.headers['location'].match(/(?<id>[a-zA-Z0-9]{8}-[a-zA-Z0-9]{4}-[a-zA-Z0-9]{4}-[a-zA-Z0-9]{4}-[a-zA-Z0-9]{12})/)[:id]
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