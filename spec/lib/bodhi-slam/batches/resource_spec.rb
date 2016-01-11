require 'spec_helper'

describe Bodhi::ResourceBatch do
  before(:all) do
    @context = Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: ENV['QA_TEST_COOKIE'] })
    @type = Bodhi::Type.new(name: "TestResource", properties: { foo: { type: "String", required: true }, bar: { type: "TestEmbeddedResource" }, baz: { type: "Integer" } })
    @embedded_type = Bodhi::Type.new(name: "TestEmbeddedResource", properties: { test: { type: "String" } }, embedded: true)

    @type.bodhi_context = @context
    @embedded_type.bodhi_context = @context

    @type.save!
    @embedded_type.save!

    Bodhi::Type.create_class_with(@type)
    Bodhi::Type.create_class_with(@embedded_type)
  end

  after(:all) do
    TestResource.delete!(@context)

    @type.delete!
    @embedded_type.delete!

    Object.send(:remove_const, :TestResource)
    Object.send(:remove_const, :TestEmbeddedResource)
  end

  before do
    @batch = Bodhi::ResourceBatch.new(TestResource)
  end

  describe "#save!(context)" do
    it "raises Bodhi::ContextErrors if the context is invalid" do
      bad_context = Bodhi::Context.new({})
      expect{ @batch.save!(bad_context) }.to raise_error(Bodhi::ContextErrors)
    end

    it "raises Bodhi::ApiErrors if the batch API request failed" do
      @batch.records = []
      expect{ @batch.save!(@context) }.to raise_error(Bodhi::ApiErrors)
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
      @batch.records = [TestResource.factory.build, TestResource.factory.build]
      @batch.save!(@context)

      expect(@batch.failed).to be_empty

      expect(@batch.created).to_not be_empty
      expect(@batch.created.size).to eq 2

      @batch.created.each do |record|
        expect(record.sys_id).to be_a String
        expect(record.errors.any?).to be false
      end

      @batch.records.each do |record|
        expect(record.sys_id).to be_a String
        expect(record.errors.any?).to be false
      end
    end
  end

  describe "#failed" do
    it "returns an array of the records that failed to be created" do
      @batch.records = [TestResource.new, TestResource.new]
      @batch.save!(@context)

      expect(@batch.created).to be_empty

      expect(@batch.failed).to_not be_empty
      expect(@batch.failed.size).to eq 2

      @batch.failed.each do |record|
        expect(record.sys_id).to be_nil
        expect(record.errors.any?).to be true
      end

      @batch.records.each do |record|
        expect(record.sys_id).to be_nil
        expect(record.errors.any?).to be true
      end
    end
  end
end