require 'spec_helper'

describe Bodhi::Validator do
  let(:validator){ Bodhi::Validator.new }
  
  describe "#validate(record, attribute, value)" do
    it "should raise a NotImplementedError" do
      expect{ validator.validate(nil, nil, nil) }.to raise_error(NotImplementedError)
    end
  end
  
  describe "#to_sym" do
    it "returns the class name as a symbol" do
      expect(validator.to_sym).to eq :validator
    end
  end
  
  describe "#underscore" do
    it "returns the class name in snake_case" do
      expect(validator.underscore).to eq "bodhi/validator"
    end
  end
  
  describe "#to_options" do
    it "should raise a NotImplementedError" do
      expect{ validator.to_options }.to raise_error(NotImplementedError)
    end
  end
end