require 'spec_helper'

describe Bodhi::StringValidation do
  let(:validation){ Bodhi::StringValidation.new }
  let(:klass) do
    Class.new do
      include Bodhi::Validations
      attr_accessor :foo
    end
  end
  let(:record){ klass.new }
  
  describe "#validate(record, attribute, value)" do
    it "should add error if :value is not a string" do
      record.foo = 12345
      validation.validate(record, :foo, record.foo)
      expect(record.errors.full_messages).to include("foo must be a String")
    end
    
    it "should not add error if :value is a string" do
      record.foo = "test"
      validation.validate(record, :foo, record.foo)
      expect(record.errors.full_messages).to_not include("foo must be a String")
    end
  end
end