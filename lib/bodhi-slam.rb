require "faraday"
require 'net/http/persistent'
require "json"
require "time"
require "SecureRandom"

require 'bodhi-slam/validations'
require 'bodhi-slam/errors'

require 'bodhi-slam/batches'
require 'bodhi-slam/context'
require 'bodhi-slam/enumerations'
require 'bodhi-slam/factory'
require 'bodhi-slam/resource'
require 'bodhi-slam/types'
require 'bodhi-slam/users'

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

  # Dynamically creates Ruby Classes for each type in the given +context+
  # 
  #   context = Bodhi::Context.new(valid_params)
  #   BodhiSlam.analyze(context) # => [#<Class:0x007fbff403e808 @name="TestType">, #<Class:0x007fbff403e808 @name="TestType2">, ...]
  def self.analyze(context)
    if context.invalid?
      raise Bodhi::ContextErrors.new(context.errors.messages), context.errors.to_a.to_s
    end

    all_enums = Bodhi::Enumeration.find_all(context)
    all_types = Bodhi::Type.find_all(context)
    all_types.collect{ |type| Bodhi::Type.create_class_with(type) }
  end
end