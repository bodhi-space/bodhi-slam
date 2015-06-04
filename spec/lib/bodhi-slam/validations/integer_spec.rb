require 'spec_helper'

describe Bodhi::IntegerValidation do
  let(:validation){ Bodhi::IntegerValidation.new }
  let(:klass) do
    Class.new do
      include Bodhi::Validations
      attr_accessor :foo
    end
  end
  let(:record){ klass.new }
  
  describe "#validate(record, attribute, value)" do
    it "should add error if :value is not an Integer" do
      record.foo = "test"
      validation.validate(record, :foo, record.foo)
      expect(record.errors.full_messages).to include("foo must be an Integer")
    end
    
    it "should not add error if :value is an Integer" do
      record.foo = 12345
      validation.validate(record, :foo, record.foo)
      expect(record.errors.full_messages).to_not include("foo must be an Integer")
    end
  end
end