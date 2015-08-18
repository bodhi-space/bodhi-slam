require 'spec_helper'

describe Bodhi::MatchesValidator do
  let(:validator){ Bodhi::MatchesValidator.new("[a-z]{5}") }
  let(:klass) do
    Class.new do
      include Bodhi::Validations
      attr_accessor :foo
    end
  end
  let(:record){ klass.new }
  
  describe "#validate(record, attribute, value)" do
    context "when :value is a single object" do
      it "should add error if :value does not match the regexp" do
        record.foo = "ABCD"
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must match [a-z]{5}")
        expect(record.errors.full_messages).to_not include("foo must only contain values matching [a-z]{5}")
      end
    
      it "should not add error if :value matches the regexp" do
        record.foo = "abcde"
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must match [a-z]{5}")
        expect(record.errors.full_messages).to_not include("foo must only contain values matching [a-z]{5}")
      end
      
      it "should not add error if :value is nil" do
        record.foo = nil
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must match [a-z]{5}")
        expect(record.errors.full_messages).to_not include("foo must only contain values matching [a-z]{5}")
      end
    end
    
    context "when :value is an array" do
      it "should add error if any :value does not match the regexp" do
        record.foo = ["abcde", "12345", "10"]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must only contain values matching [a-z]{5}")
        expect(record.errors.full_messages).to_not include("foo must match [a-z]{5}")
      end
      
      it "should not add any errors if :value is empty" do
        record.foo = []
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must only contain values matching [a-z]{5}")
        expect(record.errors.full_messages).to_not include("foo must match [a-z]{5}")
      end
      
      it "should not add any errors if all :values match the regexp" do
        record.foo = ["abc", "xyz"]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must only contain values greater than or equal to 10")
        expect(record.errors.full_messages).to_not include("foo must be greater than or equal to 10")
      end
    end
  end
  
  describe "#to_options" do
    it "should return a Hash" do
      expect(validator.to_options).to be { matches:"[a-z]{5}" }
    end
  end
end