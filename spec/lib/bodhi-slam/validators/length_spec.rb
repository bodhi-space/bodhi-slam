require 'spec_helper'

describe Bodhi::LengthValidator do
  let(:validator){ Bodhi::LengthValidator.new("[10,20]") }
  let(:klass) do
    Class.new do
      include Bodhi::Validations
      attr_accessor :foo
    end
  end
  let(:record){ klass.new }
  
  describe "#validate(record, attribute, value)" do
    context "when :value is a single object" do
      it "should add error if :value is not within the length range" do
        record.foo = "12345"
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must be [10, 20] characters long")
        expect(record.errors.full_messages).to_not include("foo must all be [10, 20] characters long")
      end
    
      it "should not add error if :value is within the length range" do
        record.foo = "123456789012345"
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must be [10, 20] characters long")
        expect(record.errors.full_messages).to_not include("foo must all be [10, 20] characters long")
      end
      
      it "should not add error if :value is nil" do
        record.foo = nil
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must be [10, 20] characters long")
        expect(record.errors.full_messages).to_not include("foo must all be [10, 20] characters long")
      end
    end
    
    context "when :value is an array" do
      it "should add error if any :value is not within the length range" do
        record.foo = ["123456789012345", "123456789012345", "123456"]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must all be [10, 20] characters long")
        expect(record.errors.full_messages).to_not include("foo must be [10, 20] characters long")
      end
      
      it "should not add any errors if :value is empty" do
        record.foo = []
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must all be [10, 20] characters long")
        expect(record.errors.full_messages).to_not include("foo must be [10, 20] characters long")
      end
      
      it "should not add any errors if all :values are within the length range" do
        record.foo = ["123456789012345", "123456789012345", "123456789012345"]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must all be [10, 20] characters long")
        expect(record.errors.full_messages).to_not include("foo must be [10, 20] characters long")
      end
    end
  end
  
  describe "#to_options" do
    it "should return a Hash" do
      expect(validator.to_options).to be { length:"[10,20]" }
    end
  end
end