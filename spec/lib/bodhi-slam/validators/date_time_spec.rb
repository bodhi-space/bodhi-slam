require 'spec_helper'

describe Bodhi::DateTimeValidator do
  let(:validator){ Bodhi::DateTimeValidator.new }
  let(:klass) do
    Class.new do
      include Bodhi::Validations
      attr_accessor :foo
    end
  end
  let(:record){ klass.new }
  
  describe "#validate(record, attribute, value)" do
    
    context "when :value is a single object" do
      it "should add error if :value is not a DateTime" do
        record.foo = 12345
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must be a DateTime")
        expect(record.errors.full_messages).to_not include("foo must contain only DateTimes")
      end
    
      it "should not add error if :value is a DateTime" do
        record.foo = Time.new("1900")
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must be a DateTime")
        expect(record.errors.full_messages).to_not include("foo must contain only DateTimes")
      end
      
      it "should not add error if :value is nil" do
        record.foo = nil
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must be a DateTime")
        expect(record.errors.full_messages).to_not include("foo must contain only DateTimes")
      end
    end
    
    context "when :value is an array" do
      it "should add error if any :value is not a DateTime" do
        record.foo = [Time.new("1900"), Time.new("1910"), "test"]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must contain only DateTimes")
        expect(record.errors.full_messages).to_not include("foo must be a DateTime")
      end
      
      it "should not add any errors if :value is empty" do
        record.foo = []
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must contain only DateTimes")
        expect(record.errors.full_messages).to_not include("foo must be a DateTime")
      end
      
      it "should not add any errors if all :values are DateTimes" do
        record.foo = [Time.new("1900"), Time.new("1900"), Time.new("1900")]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must contain only DateTimes")
        expect(record.errors.full_messages).to_not include("foo must be a DateTime")
      end
    end
  end
end