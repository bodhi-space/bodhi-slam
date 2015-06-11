require 'spec_helper'

describe Bodhi::TypeValidator do
  let(:validator){ Bodhi::TypeValidator.new("MyClass", "Reference.name") }

  describe "#value" do
    it "is a String" do
      expect(validator.value).to eq "MyClass"
    end
  end

  describe "#reference" do
    it "is a String" do
      expect(validator.reference).to eq "Reference.name"
    end
  end
end