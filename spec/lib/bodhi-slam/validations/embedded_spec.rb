require 'spec_helper'

describe Bodhi::EmbeddedValidation do
  describe "#validate(record, attribute, value)" do
    let(:embedded_klass){ Object.const_set(:TestEmbedded, Class.new) }
    let(:validation){ Bodhi::EmbeddedValidation.new(:TestEmbedded) }
    let(:klass) do
      Class.new do
        include Bodhi::Validations
        attr_accessor :foo
      end
    end
    let(:record){ klass.new }
    
    it "should add error if :value is not a type of :embedded_klass" do
      Object.const_set("TestEmbedded", Class.new) #no clue why i need to do this again here..  :(
      
      record.foo = "test"
      validation.validate(record, :foo, record.foo)
      expect(record.errors.full_messages).to include("foo must be a #{embedded_klass}")
    end
    
    it "should not add error if :value is a type of :embedded_klass" do
      record.foo = embedded_klass.new
      validation.validate(record, :foo, record.foo)
      expect(record.errors.full_messages).to_not include("foo must be a #{embedded_klass}")
    end
  end
end