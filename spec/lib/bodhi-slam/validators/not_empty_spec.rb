require 'spec_helper'

describe Bodhi::IsNotEmptyValidator do
  let(:validator){ Bodhi::IsNotEmptyValidator.new(true) }
  let(:klass) do
    Class.new do
      include Bodhi::Validations
      attr_accessor :foo
    end
  end
  let(:record){ klass.new }
  
  describe "#validate(record, attribute, value)" do
    it "does nothing if the :value is nil" do
      record.foo = nil
      validator.validate(record, :foo, record.foo)
      expect(record.errors.full_messages).to_not include("foo must not be empty")
    end

    context "when :value is an array" do
      it "should add any errors if :value is empty" do
        record.foo = []
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must not be empty")
      end

      it "should NOT add any errors if :value is not empty" do
        record.foo = ["test"]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must not be empty")
      end
    end
  end
  
  describe "#to_options" do
    it "should return a Hash" do
      expect(validator.to_options).to eq isNotEmpty: true
    end
  end
end