require 'spec_helper'

describe Bodhi::IntegerValidator do
  let(:validator){ Bodhi::IntegerValidator.new }
  let(:klass) do
    Class.new do
      include Bodhi::Validations
      attr_accessor :foo
    end
  end
  let(:record){ klass.new }
  
  describe "#validate(record, attribute, value)" do
    context "when :value is a single object" do
      it "should add error if :value is not an Integer" do
        record.foo = "test"
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must be an Integer")
        expect(record.errors.full_messages).to_not include("foo must contain only Integers")
      end
    
      it "should not add error if :value is an Integer" do
        record.foo = 12345
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must be an Integer")
        expect(record.errors.full_messages).to_not include("foo must contain only Integers")
      end
    end
    
    context "when :value is an array" do
      it "should add error if any :value is not an Integer" do
        record.foo = [1,2,"3",4]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must contain only Integers")
        expect(record.errors.full_messages).to_not include("foo must be an Integer")
      end
      
      it "should not add any errors if the :value is an empty array" do
        record.foo = []
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must contain only Integers")
        expect(record.errors.full_messages).to_not include("foo must be an Integer")
      end
      
      it "should not add any errors if all :values are Integers" do
        record.foo = [1,2,3,4]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must contain only Integers")
        expect(record.errors.full_messages).to_not include("foo must be an Integer")
      end
    end
  end
  
  describe "#to_options" do
    it "should return the validator as an option Hash" do
      expect(validator.to_options).to include({integer: true})
    end
  end
end