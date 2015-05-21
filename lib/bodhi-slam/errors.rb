module Bodhi
  class Errors < Exception
    attr_accessor :messages
    
    def initialize(errors={})
      @messages = errors
    end

    def add(name, msg)
      @messages[name] = [] unless @messages.has_key?(name)
      @messages[name].push(msg)
    end
    
    def clear
      @messages.clear
    end
    
    def full_messages
      results = []
      @messages.each{ |key, values| values.each{ |value| results.push("#{key} #{value}") }}
      results
    end
    
    def to_json
      @messages.to_json
    end
  end
end