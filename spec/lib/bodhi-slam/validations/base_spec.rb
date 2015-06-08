require 'spec_helper'

describe Bodhi::BaseValidation do
  let(:validation){ Bodhi::BaseValidation.new }
  
  describe "#validate(record, attribute, value)" do
    it "should raise a NotImplementedError" do
      expect{ validation.validate(nil, nil, nil) }.to raise_error(NotImplementedError)
    end
  end
  
  describe "#to_sym" do
    it "returns the class name as a symbol" do
      expect(validation.to_sym).to eq :base
    end
  end
  
  describe "#underscore" do
    it "returns the class name in snake_case" do
      expect(validation.underscore).to eq "bodhi/base_validation"
    end
  end
end