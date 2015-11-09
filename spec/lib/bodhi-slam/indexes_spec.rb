require 'spec_helper'

describe Bodhi::Indexes do
  let(:klass){ Class.new{ include Bodhi::Indexes } }

  describe ".index(keys, options={})" do
    it "adds a new index with the given keys and options (strings)" do
      klass.index ["test", "foo"], "unique" => true
      expect(klass.indexes.first).to be_a Bodhi::TypeIndex
      expect(klass.indexes.first.attributes).to eq keys: ["test", "foo"], options: { unique: true }
      expect(klass.indexes.first.to_json).to eq '{"keys":["test","foo"],"options":{"unique":true}}'
    end

    it "adds a new index with the given keys and options (symbols)" do
      klass.index [:test, :foo], unique: true
      expect(klass.indexes.first).to be_a Bodhi::TypeIndex
      expect(klass.indexes.first.attributes).to eq keys: ["test", "foo"], options: { unique: true }
      expect(klass.indexes.first.to_json).to eq '{"keys":["test","foo"],"options":{"unique":true}}'
    end

    it "options can be optional" do
      klass.index [:test, :foo]
      expect(klass.indexes.first).to be_a Bodhi::TypeIndex
      expect(klass.indexes.first.attributes).to eq keys: ["test", "foo"], options: Hash.new
      expect(klass.indexes.first.to_json).to eq '{"keys":["test","foo"],"options":{}}'
    end
  end

  describe ".indexes" do
    it "returns an array of all Bodhi::TypeIndex objects for the class" do
      klass.index ["test", "foo"], unique: true
      klass.index ["bar", "foo"], unique: true, name: "Bob"

      expect(klass.indexes).to be_a Array
      expect(klass.indexes.size).to eq 2
      klass.indexes.each{ |index| expect(index).to be_a Bodhi::TypeIndex }
      expect(klass.indexes.to_json).to eq '[{"keys":["test","foo"],"options":{"unique":true}},{"keys":["bar","foo"],"options":{"unique":true,"name":"Bob"}}]'
    end
  end
end