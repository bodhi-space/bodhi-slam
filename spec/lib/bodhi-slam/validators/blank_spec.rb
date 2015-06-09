require 'spec_helper'

describe Bodhi::NotBlankValidator do
  let(:validator){ Bodhi::NotBlankValidator.new }
  let(:klass) do
    Class.new do
      include Bodhi::Validations
      attr_accessor :foo
    end
  end
  let(:record){ klass.new }
  
  describe "#validate(record, attribute, value)" do
    
    context "when :value is a single object" do
      
      it "should add error if :value is a blank string" do
        record.foo = ""
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo can not be blank")
        expect(record.errors.full_messages).to_not include("foo must not contain blank Strings")
      end
    
      it "should not add error if :value is not blank" do
        record.foo = "test"
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo can not be blank")
        expect(record.errors.full_messages).to_not include("foo must not contain blank Strings")
      end
      
      it "should not add error if :value is nil" do
        record.foo = nil
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo can not be blank")
        expect(record.errors.full_messages).to_not include("foo must not contain blank Strings")
      end
    end
    
    context "when :value is an array" do
      it "should add error if any :value is a blank String" do
        record.foo = ["test", ""]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must not contain blank Strings")
        expect(record.errors.full_messages).to_not include("foo can not be blank")
      end
      
      it "should not add any errors if :value is empty" do
        record.foo = []
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must not contain blank Strings")
        expect(record.errors.full_messages).to_not include("foo can not be blank")
      end
      
      it "should not add any errors if all :values are not blank Strings" do
        record.foo = ["test", "test", "test"]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must not contain blank Strings")
        expect(record.errors.full_messages).to_not include("foo can not be blank")
      end
    end
  end
end