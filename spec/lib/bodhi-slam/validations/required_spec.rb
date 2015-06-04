require 'spec_helper'

describe Bodhi::RequiredValidation do
  let(:validation){ Bodhi::RequiredValidation.new }
  let(:klass) do
    Class.new do
      include Bodhi::Validations
      attr_accessor :foo
      validates :foo, required: true
    end
  end
  let(:record){ klass.new }
  
  describe "#validate(record, attribute, value)" do
    it "should add error if :value is nil" do
      validation.validate(record, :foo, record.foo)
      expect(record.errors.full_messages).to include("foo is required")
    end
    
    it "should not add error if :value is not nil" do
      record.foo = "test"
      validation.validate(record, :foo, record.foo)
      expect(record.errors.full_messages).to_not include("foo is required")
    end
  end
end