require 'spec_helper'

describe Bodhi::TypeValidator do
  let(:validator){ Bodhi::TypeValidator.new("MyClass", "Reference.name") }

  describe "#type" do
    it "is a String" do
      expect(validator.type).to eq "MyClass"
    end
  end

  describe "#reference" do
    it "is a String" do
      expect(validator.reference).to eq "Reference.name"
    end
  end
  
  describe "#to_options" do
    it "should return a Hash" do
      expect(validator.to_options).to be { type:"MyClass",ref:"Reference.name" }
    end
  end
end