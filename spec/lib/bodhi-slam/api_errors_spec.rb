require 'spec_helper'

describe Bodhi::ApiErrors do
  describe "#initialize(params)" do
    it "accepts a hash as a parameter" do
      errors = Bodhi::ApiErrors.new
      expect(errors).to be_a Bodhi::ApiErrors
    end
  end

  describe "#status" do
    it "contains the response status code from the request" do
      errors = Bodhi::ApiErrors.new(status: "422")
      expect(errors.status).to eq "422"
    end
  end

  describe "#body" do
    it "contains the response body from the request" do
      errors = Bodhi::ApiErrors.new(body: "test")
      expect(errors.body).to eq "test"
    end
  end
end