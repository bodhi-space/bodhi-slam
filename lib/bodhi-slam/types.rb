module Bodhi
  class Type
    include Bodhi::Validations
    
    BODHI_SYSTEM_ATTRIBUTES = [:sys_created_at, :sys_version, :sys_modified_at, :sys_modified_by,
      :sys_namespace, :sys_created_by, :sys_type_version, :sys_id]
    BODHI_TYPE_ATTRIBUTES = [:name, :namespace, :package, :embedded, :properties]
    
    attr_accessor *BODHI_TYPE_ATTRIBUTES
    attr_reader *BODHI_SYSTEM_ATTRIBUTES
    attr_reader :validations
    
    validates :name, required: true, is_not_blank: true
    validates :namespace, required: true
    validates :properties, required: true
    
    def initialize(params={})
      params.symbolize_keys!
      
      BODHI_TYPE_ATTRIBUTES.each do |attribute|
        send("#{attribute}=", params[attribute])
      end
      
      @validations = {}
      if properties
        properties.symbolize_keys!
        properties.each_pair do |attr_name, attr_properties|
          attr_properties.symbolize_keys!
          @validations[attr_name] = []
          attr_properties.each_pair do |option, value|
            underscored_name = option.to_s.gsub(/::/, '/').gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').gsub(/([a-z\d])([A-Z])/,'\1_\2').tr("-", "_").downcase.to_sym
            unless [:system, :trim, :ref, :unique, :default, :is_current_user].include? underscored_name
              klass = Bodhi::Validator.constantize(underscored_name)
              if option == :type && value == "Enumerated"
                if attr_properties[:ref].nil?
                  raise RuntimeError.new("No reference property found!  Cannot build enumeration validator for #{name}.#{attr_name}")
                end

                @validations[attr_name] << klass.new(value, attr_properties[:ref])
              else
                @validations[attr_name] << klass.new(value)
              end
            end
          end
        end
      end
    end
    
    def self.find_all(context)
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
    
      JSON.parse(result.body).collect{ |type| Bodhi::Type.new(type) }
    end
    
    def self.create_class_with(type)
      unless type.is_a? Bodhi::Type
        raise ArgumentError.new("Expected #{type.class} to be a Bodhi::Type")
      end
      
      klass = Object.const_set(type.name, Class.new {
        include BodhiResource
        include Bodhi::Validations
        attr_accessor *type.properties.keys
      })
      
      type.validations.each_pair do |attribute, validations|
        attr_options = Hash.new
        validations.each{ |validation| attr_options.merge!(validation.to_options) }
        klass.validates(attribute, attr_options)
      end
      
      klass
    end
    
    def self.create_factory_with(type, enumerations=[])
      unless type.is_a? Bodhi::Type
        raise ArgumentError.new("Expected #{type.class} to be a Bodhi::Type")
      end

      FactoryGirl.define do
        factory type.name.to_sym do
          type.properties.each_pair do |attribute, options|
            unless options[:system]

              case options[:type]
              when "GeoJSON"
                if options[:multi].nil?
                  send(attribute) { {type: "Point", coordinates: [10,20]} }
                else
                  send(attribute) { [*0..5].sample.times.collect{ {type: "Point", coordinates: [10,20]} } }
                end

              when "Boolean"
                if options[:multi].nil?
                  send(attribute) { [true, false].sample }
                else
                  send(attribute) { [*0..5].sample.times.collect{ [true, false].sample } }
                end

              when "Enumerated"
                reference = options[:ref].split('.')
                name = reference[0]
                field = reference[1]

                enum = enumerations.select{ |enumeration| enumeration.name == name }[0]
                if options[:multi].nil?
                  if field.nil?
                    send(attribute) { enum.values.sample }
                  else
                    enum.values.map!{ |value| value.symbolize_keys! }
                    send(attribute) { enum.values.sample[field.to_sym] }
                  end
                else
                  if field.nil?
                    send(attribute) { [*0..5].sample.times.collect{ enum.values.sample } }
                  else
                    send(attribute) { [*0..5].sample.times.collect{ enum.values.sample[field.to_sym] } }
                  end
                end

              when "Object"
                if options[:multi].nil?
                  send(attribute) { {SecureRandom.hex => SecureRandom.hex} }
                else
                  send(attribute) { [*0..5].sample.times.collect{ {SecureRandom.hex => SecureRandom.hex} } }
                end

              when "String"
                if options[:multi].nil?
                  send(attribute) { SecureRandom.hex }
                else
                  send(attribute) { [*0..5].sample.times.collect{ SecureRandom.hex } }
                end

              when "DateTime"
                if options[:multi].nil?
                  send(attribute) { Time.at(rand * Time.now.to_i).iso8601 }
                else
                  send(attribute) { [*0..5].sample.times.collect{ Time.at(rand * Time.now.to_i).iso8601 } }
                end

              when "Integer"
                min = -10000
                max = 10000
                if options[:min]
                  min = options[:min]
                end

                if options[:max]
                  max = options[:max]
                end

                if options[:multi].nil?
                  send(attribute) { rand(min..max) }
                else
                  send(attribute) { [*0..5].sample.times.collect{ rand(min..max) } }
                end

              when "Real"
                if options[:multi].nil?
                  send(attribute) { SecureRandom.random_number*[-1,1,1,1].sample*[10,100,1000,10000].sample }
                else
                  send(attribute) { [*0..5].sample.times.collect{ SecureRandom.random_number*[-1,1,1,1].sample*[10,100,1000,10000].sample } }
                end

              else # Its an embedded type
                if options[:multi].nil?
                  send(attribute) { FactoryGirl.build(options[:type]) }
                else
                  send(attribute) { [*0..5].sample.times.collect{ FactoryGirl.build(options[:type]) } }
                end
              end
            
            end
          end
        end
      end

    end
  end
end