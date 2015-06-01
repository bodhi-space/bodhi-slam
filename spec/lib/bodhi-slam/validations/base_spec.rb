require 'spec_helper'

describe Bodhi::BaseValidation do
  let(:error){ Bodhi::BaseValidation.new }
  
  describe "#validate(record, attribute, value)" do
    it "should raise a NotImplementedError" do
      expect{ error.validate(nil, nil, nil) }.to raise_error(NotImplementedError)
    end
  end
end