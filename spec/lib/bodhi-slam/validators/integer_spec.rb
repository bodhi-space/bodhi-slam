require 'spec_helper'

describe Bodhi::IntegerValidator do
  let(:validation){ Bodhi::IntegerValidator.new }
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
        validation.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must be an Integer")
        expect(record.errors.full_messages).to_not include("foo must contain only Integers")
      end
    
      it "should not add error if :value is an Integer" do
        record.foo = 12345
        validation.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must be an Integer")
        expect(record.errors.full_messages).to_not include("foo must contain only Integers")
      end
    end
    
    context "when :value is an array" do
      it "should add error if any :value is not an Integer" do
        record.foo = [1,2,"3",4]
        validation.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must contain only Integers")
        expect(record.errors.full_messages).to_not include("foo must be an Integer")
      end
      
      it "should not add any errors if the :value is an empty array" do
        record.foo = []
        validation.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must contain only Integers")
        expect(record.errors.full_messages).to_not include("foo must be an Integer")
      end
      
      it "should not add any errors if all :values are Integers" do
        record.foo = [1,2,3,4]
        validation.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must contain only Integers")
        expect(record.errors.full_messages).to_not include("foo must be an Integer")
      end
    end
  end
end