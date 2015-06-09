require 'spec_helper'

describe Bodhi::UrlValidator do
  let(:validator){ Bodhi::UrlValidator.new }
  let(:klass) do
    Class.new do
      include Bodhi::Validations
      attr_accessor :foo
    end
  end
  let(:record){ klass.new }
  
  describe "#validate(record, attribute, value)" do
    
    context "when :value is a single object" do
      it "should add error if :value not a valid URL" do
        record.foo = "1234"
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must be a valid URL")
        expect(record.errors.full_messages).to_not include("foo must contain only valid URLs")
      end
    
      it "should not add error if :value is valid URL" do
        record.foo = "https://google.com"
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must be a valid URL")
        expect(record.errors.full_messages).to_not include("foo must contain only valid URLs")
      end
      
      it "should not add error if :value is nil" do
        record.foo = nil
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must be a valid URL")
        expect(record.errors.full_messages).to_not include("foo must contain only valid URLs")
      end
    end
    
    context "when :value is an array" do
      it "should add error if any :value is not a valid URL" do
        record.foo = ["https://google.com", "test.com"]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must contain only valid URLs")
        expect(record.errors.full_messages).to_not include("foo must be a valid URL")
      end
      
      it "should not add any errors if :value is empty" do
        record.foo = []
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must contain only valid URLs")
        expect(record.errors.full_messages).to_not include("foo must be a valid URL")
      end
      
      it "should not add any errors if all :values are valid URLs" do
        record.foo = ["https://google.com", "http://reddit.com"]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must contain only valid URLs")
        expect(record.errors.full_messages).to_not include("foo must be a valid URL")
      end
    end
    
  end
end