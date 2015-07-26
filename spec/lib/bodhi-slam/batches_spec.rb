require 'spec_helper'

describe Bodhi::Batch do
  let(:batch){ Bodhi::Batch.new }

  describe "#records" do
    it "is an array" do
      expect(batch.records).to be_a Array
      expect(batch.records).to be_empty
    end
  end

  describe "#created" do
    it "is an array" do
      expect(batch.created).to be_a Array
      expect(batch.created).to be_empty
    end
  end

  describe "#failed" do
    it "is an array" do
      expect(batch.failed).to be_a Array
      expect(batch.failed).to be_empty
    end
  end

  describe "#save!(context)" do
    it "should raise a NotImplementedError" do
      expect{ batch.save!(nil) }.to raise_error(NotImplementedError)
    end
  end
end