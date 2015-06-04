require 'spec_helper'

describe Bodhi::TypeValidation do
  let(:klass) do
    Class.new do
      include Bodhi::Validations
      attr_accessor :foo
    end
  end
  let(:record){ klass.new }
  
  describe "#validate(record, attribute, value)" do
    it "should add error if :value does not match :type as Object" do
      validation = Bodhi::TypeValidation.new(:Object)
      validation.validate(record, :foo, record.foo)
      expect(record.errors.full_messages).to include("foo must be a Object")
    end
    
    it "should add error if :value does not match :type as Boolean" do
      validation = Bodhi::TypeValidation.new(:Boolean)
      validation.validate(record, :foo, record.foo)
      expect(record.errors.full_messages).to include("foo must be a Boolean")
    end
    
    it "should add error if :value does not match :type as String" do
      validation = Bodhi::TypeValidation.new(:String)
      validation.validate(record, :foo, record.foo)
      expect(record.errors.full_messages).to include("foo must be a String")
    end
    
    it "should add error if :value does not match :type as Integer" do
      validation = Bodhi::TypeValidation.new(:Integer)
      validation.validate(record, :foo, record.foo)
      expect(record.errors.full_messages).to include("foo must be a Integer")
    end
    
    it "should add error if :value does not match :type as DateTime" do
      validation = Bodhi::TypeValidation.new(:DateTime)
      validation.validate(record, :foo, record.foo)
      expect(record.errors.full_messages).to include("foo must be a DateTime")
    end
    
    it "should add error if :value does not match :type as Real" do
      validation = Bodhi::TypeValidation.new(:Real)
      validation.validate(record, :foo, record.foo)
      expect(record.errors.full_messages).to include("foo must be a Real")
    end
    
    it "should add error if :value does not match :type as GeoJSON" do
      validation = Bodhi::TypeValidation.new(:GeoJSON)
      validation.validate(record, :foo, record.foo)
      expect(record.errors.full_messages).to include("foo must be a GeoJSON")
    end
    
    it "should add error if :value does not match :type as Enumerated" do
      validation = Bodhi::TypeValidation.new(:Enumerated)
      validation.validate(record, :foo, record.foo)
      expect(record.errors.full_messages).to include("foo must be a Enumerated")
    end
    
    it "should add error if :value does not match :type as an Embedded Document" do
      klass = Object.const_set(:MyTestType, Class.new)
      validation = Bodhi::TypeValidation.new(:MyTestType)
      validation.validate(record, :foo, record.foo)
      expect(record.errors.full_messages).to include("foo must be a MyTestType")
    end
  end
end