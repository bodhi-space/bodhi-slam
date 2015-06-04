require 'spec_helper'

describe Bodhi::RealValidation do
  let(:validation){ Bodhi::RealValidation.new }
  let(:klass) do
    Class.new do
      include Bodhi::Validations
      attr_accessor :foo
    end
  end
  let(:record){ klass.new }
  
  describe "#validate(record, attribute, value)" do
    it "should add error if :value is not a Real (Float)" do
      record.foo = "test"
      validation.validate(record, :foo, record.foo)
      expect(record.errors.full_messages).to include("foo must be a Real (Float)")
    end
    
    it "should not add error if :value is a Real (Float)" do
      record.foo = 1.0
      validation.validate(record, :foo, record.foo)
      expect(record.errors.full_messages).to_not include("foo must be a Real (Float)")
    end
  end
end