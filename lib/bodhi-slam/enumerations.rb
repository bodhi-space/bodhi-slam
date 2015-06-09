module Bodhi
  class Enumeration
    attr_reader :name, :values
    
    def initialize(params={})
      params.symbolize_keys!
      
      @name = params[:name]
      @values = params[:values]
    end
    
    def self.find_all(context)
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
    
      JSON.parse(result.body).collect{ |enum| Bodhi::Enumeration.new(enum) }
    end
    
  end
end