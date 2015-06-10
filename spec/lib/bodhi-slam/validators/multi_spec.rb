require 'spec_helper'

describe Bodhi::MultiValidator do
  let(:validator){ Bodhi::MultiValidator.new }
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
      validator.validate(record, :foo, record.foo)
      expect(record.errors.full_messages).to include("foo must be an array")
    end
    
    it "should not add error if :value is an array" do
      record.foo = []
      validator.validate(record, :foo, record.foo)
      expect(record.errors.full_messages).to_not include("foo must be an array")
    end
  end
  
  describe "#to_options" do
    it "should return the validator as an option Hash" do
      expect(validator.to_options).to include({multi: true})
    end
  end
end