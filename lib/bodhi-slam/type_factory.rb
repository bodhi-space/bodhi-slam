module Bodhi
  class TypeFactory
    # - Create a BodhiResource from the given type definition and enumerations
    def self.create_type(type, enumerations)
      raise "Expected type to be a Hash" unless type.is_a? Hash
      raise "Expected enumerations to be an Array" unless enumerations.is_a? Array
      type.symbolize_keys!
    
      if type[:package] != "system"
        properties = type[:properties].keys.collect{ |key| key.to_sym }
        klass = Object.const_set(type[:name], Class.new {
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

        #create_factory(klass.name, type[:properties], enumerations) unless FactoryGirl.factories.registered?(klass.name)
        #puts "Created Class & Factory for: #{klass.name}"
      
        klass
      end
    end
  
    # - Create a Factory with the given name, properties, and available enumerations
    def self.create_factory(type, enumerations=[])
      raise "Expected type to be a Hash" unless type.is_a? Hash
      raise "Expected enumerations to be an Array" unless enumerations.is_a? Array
      type.symbolize_keys!
    
      FactoryGirl.define do
        factory type[:name].to_sym do
          type[:properties].each_pair do |k,v|
            unless v[:system]
            
              case v[:type]
              when "GeoJSON"
                if v[:multi].nil?
                  send(k) { {type: "Point", coordinates: [10,20]} }
                else
                  send(k) { [*0..5].sample.times.collect{ {type: "Point", coordinates: [10,20]} } }
                end

              when "Boolean"
                if v[:multi].nil?
                  send(k) { [true, false].sample }
                else
                  send(k) { [*0..5].sample.times.collect{ [true, false].sample } }
                end

              when "Enumerated"
                enum = enumerations.select{ |enumeration| enumeration[:name] == v[:ref].split('.')[0] }[0]
                if v[:multi].nil?
                  send(k) { enum[:values].sample[v[:ref].split('.')[1]] }
                else
                  send(k) { [*0..5].sample.times.collect{ enum[:values].sample[v[:ref].split('.')[1]] } }
                end

              when "Object"
                if v[:multi].nil?
                  send(k) { {"foo" => SecureRandom.hex} }
                else
                  send(k) { [*0..5].sample.times.collect{ {"foo" => SecureRandom.hex} } }
                end

              when "String"
                if v[:multi].nil?
                  send(k) { SecureRandom.hex }
                else
                  send(k) { [*0..5].sample.times.collect{ SecureRandom.hex } }
                end

              when "DateTime"
                if v[:multi].nil?
                  send(k) { Time.at(rand * Time.now.to_i).iso8601 }
                else
                  send(k) { [*0..5].sample.times.collect{ Time.at(rand * Time.now.to_i).iso8601 } }
                end

              when "Integer"
                if v[:multi].nil?
                  send(k) { SecureRandom.random_number(100) }
                else
                  send(k) { [*0..5].sample.times.collect{ SecureRandom.random_number(100) } }
                end

              when "Real"
                if v[:multi].nil?
                  send(k) { SecureRandom.random_number }
                else
                  send(k) { [*0..5].sample.times.collect{ SecureRandom.random_number } }
                end

              else # Its an embedded type
                if v[:multi].nil?
                  send(k) { FactoryGirl.build(v[:type]).attributes }
                else
                  send(k) { [*0..5].sample.times.collect{ FactoryGirl.build(v[:type]).attributes } }
                end
              end
            
            end
          end
        end
      end
    
      return FactoryGirl.factories.registered?(type[:name].to_sym)
    end
  
    # - Get all types from a namespace
    def self.get_types(context)
      raise context.errors unless context.valid?
    
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
    
      JSON.parse(result.body).collect{ |type| type.symbolize_keys }
    end
  
    # - Get all enumerations from a namespace
    def self.get_enumerations(context)
      raise context.errors unless context.valid?
    
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
    
      JSON.parse(result.body).collect{ |enum| enum.symbolize_keys }
    end
  end
end