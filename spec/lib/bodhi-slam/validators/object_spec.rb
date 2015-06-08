require 'spec_helper'

describe Bodhi::ObjectValidator do
  let(:validation){ Bodhi::ObjectValidator.new }
  let(:klass) do
    Class.new do
      include Bodhi::Validations
      attr_accessor :foo
    end
  end
  let(:record){ klass.new }
  
  describe "#validate(record, attribute, value)" do
    it "should add error if :value is not a JSON Object" do
      record.foo = 12345
      validation.validate(record, :foo, record.foo)
      expect(record.errors.full_messages).to include("foo must be a JSON Object")
    end
    
    it "should not add error if :value is a JSON Object" do
      record.foo = { foo: "test" }
      validation.validate(record, :foo, record.foo)
      expect(record.errors.full_messages).to_not include("foo must be a JSON Object")
    end
  end
end