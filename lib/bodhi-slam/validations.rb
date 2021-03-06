module Bodhi
  module Validations

    module ClassMethods

      # Returns a Hash of all validations present for the class
      #
      #   class User
      #     include Bodhi::Validations
      #     attr_accessor :name, :tags
      #
      #     validates :tags, requried: true, multi: true
      #     validates :name, required: true
      #
      #   User.validations # => {
      #     tags: [
      #       #<RequiredValidator:0x007fbff403e808 @options={}>,
      #       #<MultiValidator:0x007fbff403e808 @options={}>
      #     ],
      #     name: [
      #       #<RequiredValidator:0x007fbff403e808 @options={}>
      #     ]
      #   }
      def validators; @validators; end

      # Creates a new validation on the given +attribute+ using the supplied +options+
      #
      #   class User
      #     include Bodhi::Validations
      #     attr_accessor :name, :address, :tags
      #
      #     validates :name, type: "String", required: true
      #     validates :address, type: "PostalAddress", required: true
      #     validates :tags, type: "String", multi: true
      def validates(attribute, options)
        unless attribute.is_a? Symbol
          raise ArgumentError.new("Invalid :attribute argument. Expected #{attribute.class} to be a Symbol")
        end

        unless options.is_a? Hash
          raise ArgumentError.new("Invalid :options argument. Expected #{options.class} to be a Hash")
        end

        if options.keys.empty?
          raise ArgumentError.new("Invalid :options argument. Options can not be empty")
        end

        options = options.reduce({}) do |memo, (k, v)|
          memo.merge({ k.to_sym => v})
        end

        @validators[attribute] = []
        options.each_pair do |key, value|
          key = key.to_s.gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').gsub(/([a-z\d])([A-Z])/,'\1_\2').tr("-", "_").downcase.to_sym

          unless [:ref].include?(key)
            if key == :type && value == "Enumerated"
              @validators[attribute] << Bodhi::Validator.constantize(key).new(value, options[:ref])
            else
              @validators[attribute] << Bodhi::Validator.constantize(key).new(value)
            end
          end
        end
      end
    end

    # Returns a +Bodhi::Errors+ object that holds all information about attribute error messages.
    #
    #   class User
    #     include Bodhi::Validations
    #
    #     attr_accessor :name
    #     validates :name, required: true
    #   end
    #
    #   user = User.new
    #   user.valid? # => false
    #   user.errors # => #<Bodhi::Errors:0x007fbff403e808 @messages={name:["is required"]}>
    def errors
      @errors ||= Bodhi::Errors.new
    end

    # Runs all class validations on object and adds any errors to the +Bodhi::Errors+ object
    #
    #   class User
    #     include Bodhi::Validations
    #
    #     attr_accessor :name
    #     validates :name, required: true
    #   end
    #
    #   user = User.new
    #   user.validate! # => nil
    #   user.errors.full_messages # => ["name is required"]
    #
    #   user.name = "Bob"
    #   user.validate! # => nil
    #   user.errors.full_messages # => []
    def validate!
      errors.clear
      self.class.validators.each_pair do |attribute, array|
        value = self.send(attribute)
        array.each do |validator|
          validator.validate(self, attribute, value)
        end
      end
    end

    # Runs all validations and returns +true+ if no errors are present otherwise +false+.
    #
    #   class User
    #     include Bodhi::Validations
    #
    #     attr_accessor :name
    #     validates :name, required: true
    #   end
    #
    #   user = User.new
    #   user.valid? # => false
    #   user.errors.full_messages # => ["name is required"]
    #
    #   user.name = "Bob"
    #   user.valid? # => true
    #   user.errors.full_messages # => []
    def valid?
      validate!
      !errors.messages.any?
    end

    # Runs all validations and returns +false+ if no errors are present otherwise +true+.
    def invalid?
      !valid?
    end

    def self.included(base)
      base.extend(ClassMethods)
      base.instance_variable_set(:@validators, Hash.new)
    end
  end
end

require File.dirname(__FILE__) + "/validators.rb"
