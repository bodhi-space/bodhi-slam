require 'spec_helper'

describe Bodhi::ObjectValidator do
  let(:validator){ Bodhi::ObjectValidator.new }
  let(:klass) do
    Class.new do
      include Bodhi::Validations
      attr_accessor :foo
    end
  end
  let(:record){ klass.new }
  
  describe "#validate(record, attribute, value)" do
    
    context "when :value is a single object" do
      it "should add error if :value is not a JSON Object" do
        record.foo = 12345
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must be a JSON Object")
        expect(record.errors.full_messages).to_not include("foo must contain only JSON Objects")
      end
    
      it "should not add error if :value is a JSON Object" do
        record.foo = { foo: "test" }
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must be a JSON Object")
        expect(record.errors.full_messages).to_not include("foo must contain only JSON Objects")
      end
      
      it "should not add error if :value is nil" do
        record.foo = nil
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must be a JSON Object")
        expect(record.errors.full_messages).to_not include("foo must contain only JSON Objects")
      end
    end
    
    context "when :value is an array" do
      it "should add error if any :value is not a JSON Object" do
        record.foo = [{ foo: "test" }, { foo: "test" }, "test"]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must contain only JSON Objects")
        expect(record.errors.full_messages).to_not include("foo must be a JSON Object")
      end
      
      it "should not add any errors if :value is empty" do
        record.foo = []
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must contain only JSON Objects")
        expect(record.errors.full_messages).to_not include("foo must be a JSON Object")
      end
      
      it "should not add any errors if all :values are JSON Objects" do
        record.foo = [{ foo: "test" }, { foo: "test" }, { foo: "test" }]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must contain only JSON Objects")
        expect(record.errors.full_messages).to_not include("foo must be a JSON Object")
      end
    end
    
  end
  
  describe "#to_options" do
    it "should return the validator as an option Hash" do
      expect(validator.to_options).to include({object: true})
    end
  end
end