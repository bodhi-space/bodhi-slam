require "faraday"
require "factory_girl"
require "json"
require "time"

require 'bodhi-slam/context'
require 'bodhi-slam/errors'
require 'bodhi-slam/resource'

class BodhiSlam
  def self.context(params, &block)
    bodhi_context = BodhiContext.new params
    raise bodhi_context.errors unless bodhi_context.valid?

    #puts "Switching context to: #{bodhi_context.attributes}"
    yield bodhi_context
    #puts "Exiting context: #{bodhi_context.attributes}"
  end
  
  def self.analyze(context)
    raise context.errors unless context.valid?

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
    
    embedded_types = types.select{ |type| type["embedded"] }
    normal_types = types.select{ |type| !type["embedded"] }
    
    embedded_types.each{ |type| create_type(type, enumerations) }
    normal_types.each{ |type| create_type(type, enumerations) }
    
    #Party!
  end
  
  # - Create a BodhiResource from the given type definition and enumerations
  def self.create_type(type, enumerations)
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

      create_factory(klass.name, type["properties"], enumerations) unless FactoryGirl.factories.registered?(klass.name)
      puts "Created Class & Factory for: #{klass.name}"
    end
  end
  
  # - Create a Factory with the given name, properties, and available enumerations
  def self.create_factory(name, properties, enumerations)
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
end