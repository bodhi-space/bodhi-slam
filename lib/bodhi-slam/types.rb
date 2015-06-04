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
          attr_type = attr_properties[:type].to_sym
          @validations[attr_name] = [Bodhi::ValidationFactory.build(attr_type)]
          
          if attr_properties.has_key? :required
            @validations[attr_name].push Bodhi::ValidationFactory.build(:required)
          end
          
          if attr_properties.has_key? :multi
            @validations[attr_name].push Bodhi::ValidationFactory.build(:multi)
          end
        end
      end
    end
  end
end