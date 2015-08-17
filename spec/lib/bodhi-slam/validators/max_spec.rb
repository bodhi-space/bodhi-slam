require 'spec_helper'

describe Bodhi::MaxValidator do
  let(:validator){ Bodhi::MaxValidator.new(10) }
  let(:klass) do
    Class.new do
      include Bodhi::Validations
      attr_accessor :foo
    end
  end
  let(:record){ klass.new }
  
  describe "#validate(record, attribute, value)" do
    context "when :value is a single object" do
      it "should add error if :value is greater than the max value" do
        record.foo = 25
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must be less than or equal to 10")
        expect(record.errors.full_messages).to_not include("foo must only contain values less than or equal to 10")
      end
    
      it "should not add error if :value is less than the max value" do
        record.foo = -15
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must be less than or equal to 10")
        expect(record.errors.full_messages).to_not include("foo must only contain values less than or equal to 10")
      end
      
      it "should not add error if :value is nil" do
        record.foo = nil
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must be less than or equal to 10")
        expect(record.errors.full_messages).to_not include("foo must only contain values less than or equal to 10")
      end
    end
    
    context "when :value is an array" do
      it "should add error if any :value is greater than the max value" do
        record.foo = [5, -10, 15]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must only contain values less than or equal to 10")
        expect(record.errors.full_messages).to_not include("foo must be less than or equal to 10")
      end
      
      it "should not add any errors if :value is empty" do
        record.foo = []
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must only contain values less than or equal to 10")
        expect(record.errors.full_messages).to_not include("foo must be less than or equal to 10")
      end
      
      it "should not add any errors if all :values are less than the max value" do
        record.foo = [1,2,3,4]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must only contain values less than or equal to 10")
        expect(record.errors.full_messages).to_not include("foo must be less than or equal to 10")
      end
    end
  end
  
  describe "#to_options" do
    it "should return a Hash" do
      expect(validator.to_options).to be { length:"10".to_i }
    end
  end
end