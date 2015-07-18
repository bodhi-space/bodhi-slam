module Bodhi
  class Enumeration
    attr_reader :name, :values
    
    def initialize(params)
      # same as symbolize_keys!
      params = params.reduce({}) do |memo, (k, v)| 
        memo.merge({ k.to_sym => v})
      end

      @name = params[:name]
      @values = params[:values]
      self.class.cache[@name.to_sym] = self

      @values = @values.map do |value|
        if value.is_a? Hash
          # same as symbolize_keys!
          value = value.reduce({}) do |memo, (k, v)| 
            memo.merge({ k.to_sym => v})
          end
        else
          value
        end
      end
    end

    # Gets all Bodhi::Enumerations from a given +context+
    # and adds them to the Bodhi::Enumeration cache
    #
    #   Bodhi::Enumeration.find_all(context) # => [#<Bodhi::Enumeration:0x007fbff403e808>, #<Bodhi::Enumeration:0x007fbff403e808>, ...]
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

    # Returns a Hash of all Bodhi::Enumerations in the cache
    # 
    #   Bodhi::Enumerations.cache # => [#<Bodhi::Enumeration:0x007fbff403e808>, #<Bodhi::Enumeration:0x007fbff403e808>, ...]
    def self.cache
      @cache ||= Hash.new
    end
  end
end