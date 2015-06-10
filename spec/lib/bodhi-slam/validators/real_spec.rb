require 'spec_helper'

describe Bodhi::RealValidator do
  let(:validator){ Bodhi::RealValidator.new }
  let(:klass) do
    Class.new do
      include Bodhi::Validations
      attr_accessor :foo
    end
  end
  let(:record){ klass.new }
  
  describe "#validate(record, attribute, value)" do
    
    context "when :value is a single object" do
      it "should add error if :value is not a Real (Float)" do
        record.foo = 10
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must be a Real (Float)")
        expect(record.errors.full_messages).to_not include("foo must contain only Real (Float) numbers")
      end
    
      it "should not add error if :value is a Real (Float)" do
        record.foo = 1.0
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must be a Real (Float)")
        expect(record.errors.full_messages).to_not include("foo must contain only Real (Float) numbers")
      end
      
      it "should not add error if :value is nil" do
        record.foo = nil
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must be a Real (Float)")
        expect(record.errors.full_messages).to_not include("foo must contain only Real (Float) numbers")
      end
    end
    
    context "when :value is an array" do
      it "should add error if any :value is not a Real (Float)" do
        record.foo = [1.0, 2.5, 3]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must contain only Real (Float) numbers")
        expect(record.errors.full_messages).to_not include("foo must be a Real (Float)")
      end
      
      it "should not add any errors if :value is empty" do
        record.foo = []
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must contain only Real (Float) numbers")
        expect(record.errors.full_messages).to_not include("foo must be a Real (Float)")
      end
      
      it "should not add any errors if all :values are Reals" do
        record.foo = [1.0, 2.5, 3.99]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must contain only Real (Float) numbers")
        expect(record.errors.full_messages).to_not include("foo must be a Real (Float)")
      end
    end
    
  end
  
  describe "#to_options" do
    it "should return the validator as an option Hash" do
      expect(validator.to_options).to include({real: true})
    end
  end
end