require 'spec_helper'

describe Bodhi::BooleanValidator do
  let(:validator){ Bodhi::BooleanValidator.new }
  let(:klass) do
    Class.new do
      include Bodhi::Validations
      attr_accessor :foo
    end
  end
  let(:record){ klass.new }
  
  describe "#validate(record, attribute, value)" do
    it "should add error if :value is not a Boolean" do
      record.foo = 12345
      validator.validate(record, :foo, record.foo)
      expect(record.errors.full_messages).to include("foo must be a Boolean")
    end
    
    it "should not add error if :value is a Boolean" do
      record.foo = false
      validator.validate(record, :foo, record.foo)
      expect(record.errors.full_messages).to_not include("foo must be a Boolean")
    end
  end
end