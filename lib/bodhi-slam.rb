require "faraday"
require "factory_girl"
require "json"
require "time"

require 'bodhi-slam/context'
require 'bodhi-slam/errors'
require 'bodhi-slam/resource'
require 'bodhi-slam/types'
require 'bodhi-slam/validations'
require 'bodhi-slam/enumerations'

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
    klasses = all_types.collect{ |type| Bodhi::Type.create_class_with(type) }

    embedded_types = all_types.select{ |type| type.embedded }
    normal_types = all_types.select{ |type| !type.embedded }

    embedded_factories = embedded_types.each{ |type| Bodhi::Type.create_factory_with(type, all_enums) }
    normal_factories = normal_types.each{ |type| Bodhi::Type.create_factory_with(type, all_enums) }
    klasses
  end
end