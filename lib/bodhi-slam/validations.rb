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
      #   User.validations
      #   # => {
      #   #      tags: [
      #   #        #<RequiredValidator:0x007fbff403e808 @options={}>,
      #   #        #<MultiValidator:0x007fbff403e808 @options={}>
      #   #      ],
      #   #      name: [
      #   #        #<RequiredValidator:0x007fbff403e808 @options={}>
      #   #      ]
      #   #    }
      def validations; @validations; end
      
      # :nodoc:
      OPTIONS_FOR_VALIDATES = [:required, :multi, :url].freeze
      
      # Creates a new validation on the given +attribute+ using the supplied +options+
      #
      #   class User
      #     include Bodhi::Validations
      #     attr_accessor :name, :tags
      #
      #     validates :tags, requried: true, multi: true
      #     validates :name, required: true
      def validates(attribute, options)
        raise ArgumentError.new("Invalid :attribute argument. Expected #{attribute.class} to be a Symbol") unless attribute.is_a? Symbol
        raise ArgumentError.new("Invalid :options argument. Expected #{options.class} to be a Hash") unless options.is_a? Hash
        
        options.each_key do |key|
          unless OPTIONS_FOR_VALIDATES.include?(key)
            raise ArgumentError.new("Unknown key: #{key.inspect}. Valid keys are: #{OPTIONS_FOR_VALIDATES.map(&:inspect).join(', ')}.")
          end
        end
        
        if options[:required]
          validation = Bodhi::RequiredValidation.new
          @validations.has_key?(attribute) ? @validations[attribute].push(validation) : @validations[attribute] = [validation]
        end
        
        if options[:multi]
          validation = Bodhi::MultiValidation.new
          @validations.has_key?(attribute) ? @validations[attribute].push(validation) : @validations[attribute] = [validation]
        end
      end
    end
    
    module InstanceMethods
      
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
        self.class.validations.each_pair do |attribute, array|
          value = self.send(attribute)
          array.each do |validator|
            validator.validate(self, attribute, value)
          end
        end
      end
      
    end
    
    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)
      base.instance_variable_set(:@validations, Hash.new)
    end
  end
end

Dir[File.dirname(__FILE__) + "/validations/*.rb"].each { |file| require file }