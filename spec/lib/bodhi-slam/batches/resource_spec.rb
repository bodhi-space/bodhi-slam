require 'spec_helper'

describe Bodhi::ResourceBatch do
  let(:batch){ Bodhi::ResourceBatch.new("Test") }
  let(:context){ Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: ENV['QA_TEST_COOKIE'] }) }

  before do
    Object.const_set("Test", Class.new{ include Bodhi::Resource; attr_accessor :Brandon, :Olia, :Alisa })

    Test.validates :Brandon, type: "Boolean"
    Test.validates :Olia, type: "Integer"
    Test.validates :Alisa, type: "String"

    Test.factory.add_generator("Brandon", type: "Boolean")
    Test.factory.add_generator("Olia", type: "Integer")
    Test.factory.add_generator("Alisa", type: "String")
  end

  after do
    Test.delete_all(context)
    Object.send(:remove_const, :Test)
  end

  describe "#save!(context)" do
    it "raises Bodhi::ContextErrors if the context is invalid" do
      bad_context = Bodhi::Context.new({})
      expect{ batch.save!(bad_context) }.to raise_error(Bodhi::ContextErrors)
    end

    it "raises Bodhi::ApiErrors if the batch API request failed" do
      batch.records = []
      expect{ batch.save!(context) }.to raise_error(Bodhi::ApiErrors)
    end
  end

  describe "#records" do
    it "returns an array of all records in the batch" do
      test_batch = Bodhi::ResourceBatch.new("Test", [1,2,3])
      expect(test_batch.records).to match_array([1,2,3])
    end
  end

  describe "#created" do
    it "returns an array of the records that were sucessfully created" do
      batch.records = [Test.factory.build, Test.factory.build]
      batch.save!(context)

      expect(batch.failed).to be_empty

      expect(batch.created).to_not be_empty
      expect(batch.created.size).to eq 2

      batch.created.each do |record|
        expect(record.sys_id).to be_a String
        expect(record.errors.any?).to be false
      end

      batch.records.each do |record|
        expect(record.sys_id).to be_a String
        expect(record.errors.any?).to be false
      end
    end
  end

  describe "#failed" do
    it "returns an array of the records that failed to be created" do
      batch.records = [Test.factory.build(Brandon: "1234"), Test.factory.build(Brandon: 10)]
      batch.save!(context)

      expect(batch.created).to be_empty

      expect(batch.failed).to_not be_empty
      expect(batch.failed.size).to eq 2

      batch.failed.each do |record|
        expect(record.sys_id).to be_nil
        expect(record.errors.any?).to be true
      end

      batch.records.each do |record|
        expect(record.sys_id).to be_nil
        expect(record.errors.any?).to be true
      end
    end
  end
end