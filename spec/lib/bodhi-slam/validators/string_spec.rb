require 'spec_helper'

describe Bodhi::StringValidator do
  let(:validator){ Bodhi::StringValidator.new }
  let(:klass) do
    Class.new do
      include Bodhi::Validations
      attr_accessor :foo
    end
  end
  let(:record){ klass.new }
  
  describe "#validate(record, attribute, value)" do
    
    context "when :value is a single object" do
      it "should add error if :value is not a string" do
        record.foo = 12345
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must be a String")
        expect(record.errors.full_messages).to_not include("foo must contain only Strings")
      end
    
      it "should not add error if :value is a string" do
        record.foo = "test"
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must be a String")
        expect(record.errors.full_messages).to_not include("foo must contain only Strings")
      end
      
      it "should not add error if :value is nil" do
        record.foo = nil
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must be a String")
        expect(record.errors.full_messages).to_not include("foo must contain only Strings")
      end
    end
    
    context "when :value is an array" do
      it "should add error if any :value is not a JSON Object" do
        record.foo = ["test", "test", 12345]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must contain only Strings")
        expect(record.errors.full_messages).to_not include("foo must be a String")
      end
      
      it "should not add any errors if :value is empty" do
        record.foo = []
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must contain only Strings")
        expect(record.errors.full_messages).to_not include("foo must be a String")
      end
      
      it "should not add any errors if all :values are Strings" do
        record.foo = ["test", "test", "test"]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must contain only Strings")
        expect(record.errors.full_messages).to_not include("foo must be a String")
      end
    end
    
  end
  
  describe "#to_options" do
    it "should return the validator as an option Hash" do
      expect(validator.to_options).to include({string: true})
    end
  end
end