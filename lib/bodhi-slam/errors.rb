module Bodhi
  class Errors < Exception
    attr_accessor :messages
    
    def initialize(errors={})
      @messages = errors
    end

    def add(symbol, msg)
      @messages[symbol] = [] unless @messages.has_key?(symbol)
      @messages[symbol].push(msg)
    end
    
    def clear
      @messages.clear
    end
    
    def full_messages
      results = []
      @messages.each{ |key, values| values.each{ |value| results.push("#{key} #{value}") }}
      results
    end
  end
end