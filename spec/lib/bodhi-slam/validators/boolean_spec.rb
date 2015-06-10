require 'spec_helper'

describe Bodhi::BooleanValidator do
  let(:validator){ Bodhi::BooleanValidator.new }
  let(:klass) do
    Class.new do
      include Bodhi::Validations
      attr_accessor :foo
    end
  end
  let(:record){ klass.new }
  
  describe "#validate(record, attribute, value)" do
    
    context "when :value is a single object" do
      it "should add error if :value is not a Boolean" do
        record.foo = 12345
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must be a Boolean")
        expect(record.errors.full_messages).to_not include("foo must contain only Booleans")
      end
    
      it "should not add error if :value is a Boolean" do
        record.foo = false
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must be a Boolean")
        expect(record.errors.full_messages).to_not include("foo must contain only Booleans")
      end
      
      it "should not add error if :value is nil" do
        record.foo = nil
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must be a Boolean")
        expect(record.errors.full_messages).to_not include("foo must contain only Booleans")
      end
    end
    
    context "when :value is an array" do
      it "should add error if any :value is not a Boolean" do
        record.foo = [true, false, Class.new]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must contain only Booleans")
        expect(record.errors.full_messages).to_not include("foo must be a Boolean")
      end
      
      it "should not add any errors if :value is empty" do
        record.foo = []
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must contain only Booleans")
        expect(record.errors.full_messages).to_not include("foo must be a Boolean")
      end
      
      it "should not add any errors if all :values are Booleans" do
        record.foo = [true, false, true, false]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must contain only Booleans")
        expect(record.errors.full_messages).to_not include("foo must be a Boolean")
      end
    end
  end
  
  describe "#to_options" do
    it "should return the validator as an option Hash" do
      expect(validator.to_options).to include({boolean: true})
    end
  end
end