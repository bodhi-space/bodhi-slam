require 'spec_helper'

describe Bodhi::EnumeratedValidator do
  let(:validator){ Bodhi::EnumeratedValidator.new("Currency.name", ["USD", "GBP"]) }
  let(:klass) do
    Class.new do
      include Bodhi::Validations
      attr_accessor :foo
    end
  end
  let(:record){ klass.new }
  
  describe "#validate(record, attribute, value)" do
    
    context "when :value is a single object" do
      it "should add error if :value is not present in the given Enumeration" do
        record.foo = "TEST"
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo is not a Currency.name")
      end
    
      it "should not add error if :value is present in the given Enumeration" do
        record.foo = "USD"
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo is not a Currency.name")
      end
      
      it "should not add error if :value is nil" do
        record.foo = nil
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo is not a Currency.name")
        expect(record.errors.full_messages).to_not include("foo must contain only Currency.name values")
      end
    end
    
    context "when :value is an array" do
      it "should add error if any :value is not present in the given Enumeration" do
        record.foo = ["USD", "GBP", "TEST"]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must contain only Currency.name values")
        expect(record.errors.full_messages).to_not include("foo is not a Currency.name")
      end
      
      it "should not add any errors if :value is empty" do
        record.foo = []
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must contain only Currency.name values")
        expect(record.errors.full_messages).to_not include("foo is not a Currency.name")
      end
      
      it "should not add any errors if all :values are present in the given Enumeration" do
        record.foo = ["USD", "USD", "GBP"]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must contain only Currency.name values")
        expect(record.errors.full_messages).to_not include("foo is not a Currency.name")
      end
    end
  end
end