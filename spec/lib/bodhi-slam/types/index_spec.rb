require 'spec_helper'

describe Bodhi::TypeIndex do
  describe "#initialize(options={})" do
    it "returns a new Bodhi::TypeIndex object" do
      normal_index = Bodhi::TypeIndex.new(keys: [ "test" ], options: { unique: true })
      blank_index = Bodhi::TypeIndex.new

      expect(normal_index).to be_a Bodhi::TypeIndex
      expect(blank_index).to be_a Bodhi::TypeIndex

      expect(normal_index.valid?).to be true
      expect(blank_index.valid?).to be false
      expect(blank_index.errors.to_a).to include "keys is required"

      blank_index.keys = "test"
      expect(blank_index.valid?).to be false
      expect(blank_index.errors.to_a).to include "keys must be an array"

      blank_index.keys = [12345, 102030]
      expect(blank_index.valid?).to be false
      expect(blank_index.errors.to_a).to include "keys must contain only Strings"
    end
  end

  describe "#attributes" do
    it "returns the objects attributes as a Hash" do
      index = Bodhi::TypeIndex.new(keys: [ "test" ], options: { unique: true })
      expect(index.attributes).to eq keys: [ "test" ], options: { unique: true }
    end
  end

  describe "#to_json" do
    it "returns the objects attributes as json" do
      index = Bodhi::TypeIndex.new(keys: [ "test", "foo" ], options: { unique: true })
      expect(index.to_json).to eq '{"keys":["test","foo"],"options":{"unique":true}}'
    end
  end
end