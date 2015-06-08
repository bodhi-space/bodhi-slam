require 'spec_helper'

describe Bodhi::EnumeratedValidator do
  let(:validation){ Bodhi::EnumeratedValidator.new("Currency.name", ["USD", "GBP"]) }
  let(:klass) do
    Class.new do
      include Bodhi::Validations
      attr_accessor :foo
    end
  end
  let(:record){ klass.new }
  
  describe "#validate(record, attribute, value)" do
    it "should add error if :value is not present in the given Enumeration" do
      record.foo = "TEST"
      validation.validate(record, :foo, record.foo)
      expect(record.errors.full_messages).to include("foo is not a Currency.name")
    end
    
    it "should not add error if :value is present in the given Enumeration" do
      record.foo = "USD"
      validation.validate(record, :foo, record.foo)
      expect(record.errors.full_messages).to_not include("foo is not a Currency.name")
    end
  end
end