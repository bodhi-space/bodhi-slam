require 'spec_helper'

describe Bodhi::MultiValidation do
  let(:validation){ Bodhi::MultiValidation.new }
  let(:klass) do
    Class.new do
      include Bodhi::Validations
      attr_accessor :foo
      validates :foo, multi: true
    end
  end
  let(:record){ klass.new }
  
  describe "#validate(record, attribute, value)" do
    it "should add error if :value is not an array" do
      validation.validate(record, :foo, record.foo)
      expect(record.errors.full_messages).to include("foo must be an array")
    end
    
    it "should not add error if :value is an array" do
      record.foo = []
      validation.validate(record, :foo, record.foo)
      expect(record.errors.full_messages).to_not include("foo must be an array")
    end
  end
end