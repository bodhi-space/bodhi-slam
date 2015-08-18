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
      if context.invalid?
        raise Bodhi::ContextErrors.new(context.errors.messages), context.errors.to_a.to_s
      end

      result = context.connection.get do |request|
        request.url "/#{context.namespace}/enums"
        request.headers[context.credentials_header] = context.credentials
      end

      if result.status != 200
        raise Bodhi::ApiErrors.new(body: result.body, status: result.status), "status: #{result.status}, body: #{result.body}"
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