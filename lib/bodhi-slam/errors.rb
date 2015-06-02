module Bodhi
  class Errors < Exception
    include Enumerable
    attr_accessor :messages
    
    def initialize(errors={})
      @messages = errors
    end
    
    # Adds the given +message+ to the errors hash under the +name+ key
    #
    # user.errors.add(:test, "has bad value")
    # user.errors.any?  # => true
    def add(name, message)
      @messages.has_key?(name) ? @messages[name].push(message) : @messages[name] = [message]
    end
    
    # Clears all error messages
    #
    # user.errors.add(:name, "is wrong")
    # user.errors.clear # => nil
    # user.errors.any?  # => false
    def clear
      @messages.clear
    end
    
    # Returns an array of all error messages
    def full_messages
      results = []
      @messages.each{ |key, values| values.each{ |value| results.push("#{key} #{value}") }}
      results
    end
    alias :to_a :full_messages
    
    # Converts the messages hash to json
    def to_json
      @messages.to_json
    end
    
    # Iterates through each error key, value pair in the error messages hash.
    # Yields the attribute and the error for that attribute. If the attribute
    # has more than one error message, yields once for each error message.
    # 
    # user.errors.add(:test, "is required")
    # user.errors.each do |attribute, error|
    #   # yields :test and "is required"
    # end
    # 
    # user.errors.add(:foo, "is awesome!")
    # user.errors.each do |attribute, error|
    #   # yields :test and "is required"
    #   # then yields :foo and "is awesome!"
    # end
    def each
      @messages.each_key do |attribute|
        @messages[attribute].each{ |error| yield attribute, error }
      end
    end
    
    # Returns +true+ if the error messages include an error for the given key
    # +attribute+, +false+ otherwise.
    #
    #   user.errors.messages        # => {:name=>["is required"]}
    #   user.errors.include?(:name) # => true
    #   user.errors.include?(:foo)  # => false
    def include?(attribute)
      !@messages[attribute].nil?
    end
    alias :has_key? :include?
    alias :key? :include?
    
    # When passed a symbol or a name of a method, returns an array of errors
    # for the method.
    #
    #   user.errors[:name]  # => ["is required"]
    #   user.errors['name'] # => ["is required"]
    def [](attribute)
      @messages[attribute.to_sym]
    end
    
    # Returns the number of error messages.
    #
    #   user.errors.add(:name, "is required")
    #   user.errors.size # => 1
    #   user.errors.add(:name, "can not be blank")
    #   user.errors.size # => 2
    def size
      full_messages.size
    end
    alias :count :size
    
    # Returns +true+ if no errors are present, +false+ otherwise.
    #
    # user.errors.add(:name, "test error")
    # user.errors.empty?  # => false
    def empty?
      size == 0
    end
    alias :blank? :empty?
  end
end