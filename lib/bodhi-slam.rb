require "faraday"
require "factory_girl"
require "json"
require "time"

require 'bodhi-slam/context'
require 'bodhi-slam/errors'
require 'bodhi-slam/resource'
require 'bodhi-slam/type_factory'
require 'bodhi-slam/validations'

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
    
    klasses = []
    types = Bodhi::TypeFactory.get_types(context)
    enumerations = Bodhi::TypeFactory.get_enumerations(context)
    
    embedded_types = types.select{ |type| type["embedded"] }
    normal_types = types.select{ |type| !type["embedded"] }
    
    klasses.push(embedded_types.collect{ |type| Bodhi::TypeFactory.create_type(type, enumerations) })
    klasses.push(normal_types.collect{ |type| Bodhi::TypeFactory.create_type(type, enumerations) })
    
    klasses.flatten!
    klasses.delete_if{ |klass| klass.nil? }
  end
end