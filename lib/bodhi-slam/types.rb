module Bodhi
  class Type
    include Bodhi::Validations

    BODHI_SYSTEM_ATTRIBUTES = [:sys_created_at, :sys_version, :sys_modified_at, :sys_modified_by,
      :sys_namespace, :sys_created_by, :sys_type_version, :sys_id, :sys_embeddedType]
    BODHI_TYPE_ATTRIBUTES = [:name, :namespace, :package, :embedded, :properties]

    attr_accessor *BODHI_TYPE_ATTRIBUTES
    attr_reader *BODHI_SYSTEM_ATTRIBUTES
    attr_reader :validations

    validates :name, required: true, is_not_blank: true
    validates :namespace, required: true
    validates :properties, required: true

    def initialize(params={})
      # same as symbolize_keys!
      params = params.reduce({}) do |memo, (k, v)| 
        memo.merge({ k.to_sym => v})
      end

      # set attributes
      BODHI_TYPE_ATTRIBUTES.each do |attribute|
        send("#{attribute}=", params[attribute])
      end

      # build validator objects
      @validations = {}
      if properties
        properties.each_pair do |attr_name, attr_properties|
          @validations[attr_name.to_sym] = []
          attr_properties.each_pair do |option, value|
            underscored_name = option.to_s.gsub(/::/, '/').gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').gsub(/([a-z\d])([A-Z])/,'\1_\2').tr("-", "_").downcase.to_sym
            unless [:system, :trim, :ref, :unique, :default, :is_current_user, :to_lower].include? underscored_name
              klass = Bodhi::Validator.constantize(underscored_name)
              if option.to_s == "type" && value == "Enumerated"
                if attr_properties["ref"].nil?
                  raise RuntimeError.new("No reference property found!  Cannot build enumeration validator for #{name}.#{attr_name}")
                end
                @validations[attr_name.to_sym] << klass.new(value, attr_properties["ref"])
              else
                @validations[attr_name.to_sym] << klass.new(value)
              end
            end
          end
        end
      end
    end

    def self.find_all(context)
      raise context.errors unless context.valid?
      page = 1
      all_records = []

      begin
        result = context.connection.get do |request|
          request.url "/#{context.namespace}/types?paging=page:#{page}"
          request.headers[context.credentials_header] = context.credentials
        end

        if result.status != 200
          errors = JSON.parse result.body
          errors.each{|error| error['status'] = result.status } if errors.is_a? Array
          errors["status"] = result.status if errors.is_a? Hash
          raise errors.to_s
        end

        page += 1
        records = JSON.parse(result.body)
        all_records << records
      end while records.size == 100

      all_records.flatten.collect{ |type| Bodhi::Type.new(type) }
    end

    def self.create_class_with(type)
      unless type.is_a? Bodhi::Type
        raise ArgumentError.new("Expected #{type.class} to be a Bodhi::Type")
      end

      klass = Object.const_set(type.name, Class.new {
        include Bodhi::Resource
        attr_accessor *type.properties.keys
      })

      type.validations.each_pair do |attribute, validations|
        attr_options = Hash.new
        validations.each{ |validation| attr_options.merge!(validation.to_options) }
        klass.validates(attribute, attr_options)
        klass.factory.add_generator(attribute, attr_options)
      end

      klass
    end

  end
end