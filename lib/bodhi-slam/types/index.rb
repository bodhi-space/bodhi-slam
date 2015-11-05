module Bodhi
  class TypeIndex
    include Bodhi::Validations

    ATTRIBUTES = [:keys, :options]
    attr_accessor *ATTRIBUTES

    validates :keys, required: true, multi: true, type: "String"
    validates :options, type: "Object"

    def initialize(params={})
      params.each do |param_key, param_value|
        send("#{param_key}=", param_value)
      end
    end

    # Returns a Hash of the Objects form attributes
    # 
    #   s = SomeResource.new(foo:"test", bar:12345)
    #   s.attributes # => { foo: "test", bar: 12345 }
    def attributes
      result = Hash.new
      ATTRIBUTES.each do |attribute|
        result[attribute] = send(attribute)
      end
      result.delete_if { |k, v| v.nil? }
      result
    end

    # Returns all the Objects attributes as JSON.
    # It converts any nested Objects to JSON if they respond to +to_json+
    # 
    #   s = SomeResource.new(foo:"test", bar:12345)
    #   s.to_json # => "{ 'foo':'test', 'bar':12345 }"
    def to_json(base=nil)
      super if base
      attributes.to_json
    end
  end
end