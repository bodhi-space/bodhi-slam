require "faraday"
require 'net/http/persistent'
require "json"
require "time"

require 'bodhi-slam/context'
require 'bodhi-slam/errors'
require 'bodhi-slam/resource'
require 'bodhi-slam/types'
require 'bodhi-slam/validations'
require 'bodhi-slam/enumerations'
require 'bodhi-slam/factory'

class BodhiSlam
  def self.context(params, &block)
    bodhi_context = Bodhi::Context.new params
    raise bodhi_context.errors unless bodhi_context.valid?

    #puts "Switching context to: #{bodhi_context.attributes}"
    yield bodhi_context
    #puts "Exiting context: #{bodhi_context.attributes}"
  end
  
  def self.analyze(context)
    raise context.errors unless context.valid?

    all_types = Bodhi::Type.find_all(context)
    all_enums = Bodhi::Enumeration.find_all(context)
    all_types.collect{ |type| Bodhi::Type.create_class_with(type) }
  end
end