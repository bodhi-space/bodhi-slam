require 'spec_helper'

describe Bodhi::IsEmailValidator do
  let(:validator){ Bodhi::IsEmailValidator.new }
  let(:klass) do
    Class.new do
      include Bodhi::Validations
      attr_accessor :foo
    end
  end
  let(:record){ klass.new }
  
  describe "#validate(record, attribute, value)" do
    context "when :value is a single object" do
      it "should add error if :value is not an email" do
        record.foo = "test@com"
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must be a valid email address")
        expect(record.errors.full_messages).to_not include("foo must only contain valid email addresses")
      end
    
      it "should not add error if :value is an email" do
        record.foo = "test@email.com"
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must be a valid email address")
        expect(record.errors.full_messages).to_not include("foo must only contain valid email addresses")
      end
      
      it "should not add error if :value is nil" do
        record.foo = nil
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must be a valid email address")
        expect(record.errors.full_messages).to_not include("foo must only contain valid email addresses")
      end
    end
    
    context "when :value is an array" do
      it "should add error if any :value is not an email" do
        record.foo = ["test@email.com", "test@email.com", "test.com"]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must only contain valid email addresses")
        expect(record.errors.full_messages).to_not include("foo must be a valid email address")
      end
      
      it "should not add any errors if :value is empty" do
        record.foo = []
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must only contain valid email addresses")
        expect(record.errors.full_messages).to_not include("foo must be a valid email address")
      end
      
      it "should not add any errors if all :values are emails" do
        record.foo = ["1234@email.com", "test@email.com", "foo.bar@test.org"]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must only contain valid email addresses")
        expect(record.errors.full_messages).to_not include("foo must be a valid email address")
      end
    end
  end
  
  describe "#to_options" do
    it "should return a Hash" do
      expect(validator.to_options).to be { is_email:true }
    end
  end
end