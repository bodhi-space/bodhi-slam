require 'spec_helper'

describe Bodhi::PrecisionValidator do
  let(:validator){ Bodhi::PrecisionValidator.new(2) }
  let(:klass) do
    Class.new do
      include Bodhi::Validations
      attr_accessor :foo
    end
  end
  let(:record){ klass.new }

  describe "#validate(record, attribute, value)" do
    context "when :value is a single object" do
      it "should add error if :value does not have the correct decimal places" do
        record.foo = 1.234
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must have 2 decimal points")
        expect(record.errors.full_messages).to_not include("foo must contain only values with 2 decimal points")
      end
    
      it "should not add error if :value has the correct decimal places" do
        record.foo = 1.23
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must have 2 decimal points")
        expect(record.errors.full_messages).to_not include("foo must contain only values with 2 decimal points")
      end
      
      it "should not add error if :value is nil" do
        record.foo = nil
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must have 2 decimal points")
        expect(record.errors.full_messages).to_not include("foo must contain only values with 2 decimal points")
      end
    end
    
    context "when :value is an array" do
      it "should add error if any :value does not have the correct decimal places" do
        record.foo = [1.23, 1.234]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must contain only values with 2 decimal points")
        expect(record.errors.full_messages).to_not include("foo must have 2 decimal points")
      end
      
      it "should not add any errors if :value is empty" do
        record.foo = []
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must have 2 decimal points")
        expect(record.errors.full_messages).to_not include("foo must contain only values with 2 decimal points")
      end
      
      it "should not add any errors if all :values have the correct decimal places" do
        record.foo = [1.23, 5.67]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must have 2 decimal points")
        expect(record.errors.full_messages).to_not include("foo must contain only values with 2 decimal points")
      end
    end
  end
end