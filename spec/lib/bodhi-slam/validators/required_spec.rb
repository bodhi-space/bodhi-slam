require 'spec_helper'

describe Bodhi::RequiredValidator do
  let(:validator){ Bodhi::RequiredValidator.new }
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
      validator.validate(record, :foo, record.foo)
      expect(record.errors.full_messages).to include("foo is required")
    end
    
    it "should not add error if :value is not nil" do
      record.foo = "test"
      validator.validate(record, :foo, record.foo)
      expect(record.errors.full_messages).to_not include("foo is required")
    end
  end
  
  describe "#to_options" do
    it "should return the validator as an option Hash" do
      expect(validator.to_options).to include({required: true})
    end
  end
end