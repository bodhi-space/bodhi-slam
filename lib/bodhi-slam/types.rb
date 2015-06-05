module Bodhi
  class Type
    include Bodhi::Validations
    
    BODHI_SYSTEM_ATTRIBUTES = [:sys_created_at, :sys_version, :sys_modified_at, :sys_modified_by,
      :sys_namespace, :sys_created_by, :sys_type_version, :sys_id]
    BODHI_TYPE_ATTRIBUTES = [:name, :namespace, :package, :embedded, :properties]
    
    attr_accessor *BODHI_TYPE_ATTRIBUTES
    attr_reader *BODHI_SYSTEM_ATTRIBUTES
    attr_reader :validations
    
    validates :name, required: true, not_blank: true
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
          @validations[attr_name] = Bodhi::ValidationFactory.build(attr_properties)
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
  end
end