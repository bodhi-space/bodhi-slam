require "json"
require "time"
require 'faraday'
require 'SecureRandom'
require 'faraday_middleware'
require 'net/http/persistent'
require 'regexp-examples'

require 'bodhi-slam/support'
require 'bodhi-slam/validations'
require 'bodhi-slam/errors'
require 'bodhi-slam/context'

require 'bodhi-slam/properties'
require 'bodhi-slam/indexes'
require 'bodhi-slam/associations'

require 'bodhi-slam/batches'
require 'bodhi-slam/enumerations'
require 'bodhi-slam/factory'
require 'bodhi-slam/resource'
require 'bodhi-slam/types'
require 'bodhi-slam/users'
require 'bodhi-slam/profiles'
require 'bodhi-slam/queries'

class BodhiSlam
  # Defines a context to interact with the Bodhi API
  # Including a +server+, +namespace+, +username+, +password+ or +cookie+
  #
  #   context = Bodhi::Context.new(server: "https://test.com", namespace: "MyNamespace", username: "MyUser", password: "MyPassword")
  #   context = Bodhi::Context.new(server: "https://test.com", namespace: "MyNamespace", username: "MyUser", cookie: "MyAuthCookie")
  def self.context(params, &block)
    bodhi_context = Bodhi::Context.new params

    if bodhi_context.invalid?
      raise Bodhi::ContextErrors.new(bodhi_context.errors.messages), bodhi_context.errors.to_a.to_s
    end

    yield bodhi_context
  end

  def self.define_resources(context, options={})
    options = Bodhi::Support.symbolize_keys(options)

    if context.invalid?
      raise Bodhi::ContextErrors.new(context.errors.messages), context.errors.to_a.to_s
    end

    enumerations = Bodhi::Enumeration.find_all(context)

    if options[:include].is_a? Array
      types = Bodhi::Type.where("{name: { $in: #{options[:include].map(&:to_s)} }}").from(context).all
    elsif options[:except].is_a? Array
      types = Bodhi::Type.where("{name: { $nin: #{options[:except].map(&:to_s)} }}").from(context).all
    else
      types = Bodhi::Type.find_all(context)
    end

    types.collect do |type|
      begin
        Bodhi::Type.create_class_with(type)
      rescue Exception => error
        puts "WARNING: Unable to create class for #{type.name}.  The following error was encountered: #{error}"
      end
    end
  end

  # Dynamically creates Ruby Classes for each type in the given +context+
  # 
  #   context = Bodhi::Context.new(valid_params)
  #   BodhiSlam.analyze(context) # => [#<Class:0x007fbff403e808 @name="TestType">, #<Class:0x007fbff403e808 @name="TestType2">, ...]
  def self.analyze(context)
    puts "WARNING: The method BodhiSlam.analyze(context) has been depreciated and will be removed by version 1.0"
    if context.invalid?
      raise Bodhi::ContextErrors.new(context.errors.messages), context.errors.to_a.to_s
    end

    all_enums = Bodhi::Enumeration.find_all(context)
    all_types = Bodhi::Type.find_all(context)
    all_types.collect do |type|
      begin
        Bodhi::Type.create_class_with(type)
      rescue Exception => error
        puts "WARNING: Unable to create class for #{type.name}.  The following error was encountered: #{error}"
      end
    end
  end
end