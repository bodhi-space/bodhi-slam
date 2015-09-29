require 'spec_helper'

describe Bodhi::Resource do
  let(:context){ Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: ENV['QA_TEST_COOKIE'] }) }

  before do
    Object.const_set("TestResource", Class.new{ include Bodhi::Resource; attr_accessor :foo })
    TestResource.factory.add_generator("foo", type: "String")

    Object.const_set("Test", Class.new{ include Bodhi::Resource; attr_accessor :Brandon, :Olia, :Alisa })
    Test.factory.add_generator("Brandon", type: "Boolean")
    Test.factory.add_generator("Olia", type: "Integer")
    Test.factory.add_generator("Alisa", type: "String")
  end

  after do
    Test.delete_all(context)
    Object.send(:remove_const, :TestResource)
    Object.send(:remove_const, :Test)
  end

  it "includes Bodhi::Validations" do
    expect(TestResource.ancestors).to include Bodhi::Validations
  end

  describe "#attributes" do
    it "returns the objects form attributes" do
      test = TestResource.factory.build
      expect(test.attributes).to have_key :foo
      expect(test.attributes[:foo]).to be_a String
    end

    it "does not return the objects system attributes" do
      test = TestResource.factory.build
      expect(test.attributes.keys).to_not include(Bodhi::Resource::SYSTEM_ATTRIBUTES)
    end
  end

  describe "#save!" do
    it "should raise Bodhi::ApiErrors if the object could not be saved" do
      test = Test.factory.build(Brandon: 12345)
      test.bodhi_context = context
      expect{ test.save! }.to raise_error(Bodhi::ApiErrors)
    end

    it "should POST the objects attributes to the cloud" do
      test = Test.factory.build
      test.bodhi_context = context
      expect{ test.save! }.to_not raise_error
    end
  end

  describe "#delete!" do
    it "raises Bodhi::ApiErrors if the object could not be deleted" do
      record = Test.factory.create(context)
      record.sys_id = nil
      expect{ record.delete! }.to raise_error(Bodhi::ApiErrors)
    end

    it "should DELETE the object from the cloud" do
      record = Test.factory.create(context)
      expect{ record.delete! }.to_not raise_error
    end
  end

  describe "#patch!(params)" do
    it "raises Bodhi::ApiErrors if the object could not be patched" do
      record = Test.factory.create(context)
      expect{ record.patch!("[{}]") }.to raise_error(Bodhi::ApiErrors)
    end

    it "updates the record with the given patch arguments" do
      record = Test.factory.create(context)
      record.patch!([{ op: "replace", path: "/Alisa", value: "hello world" }])

      result = Test.find(context, record.sys_id)
      expect(result.Alisa).to eq "hello world"
    end
  end

  describe ".save_batch(context, records)" do
    it "saves and returns a batch of the records" do
      records = [Test.factory.build, Test.factory.build]
      result = Test.save_batch(context, records)
      expect(result).to be_a Bodhi::ResourceBatch
      expect(result.failed).to be_empty
      expect(result.created).to match_array(records)
    end
  end

  describe ".find(context, id)" do
    it "should raise Bodhi::Error if context is not valid" do
      bad_context = Bodhi::Context.new({})
      expect{ Test.find(bad_context, 1234) }.to raise_error(Bodhi::ContextErrors, '["server is required", "namespace is required"]')
    end

    it "should raise Bodhi::ApiErrors if :id is not present" do
      expect{ Test.find(context, "12345") }.to raise_error(Bodhi::ApiErrors)
    end

    it "should return the resource with the given id" do
      record = Test.factory.create(context)
      result = Test.find(context, record.sys_id)
      expect(result).to be_a Test

      puts "\033[33mFound Resource\033[0m: \033[36m#{result.attributes}\033[0m"
      expect(result.attributes).to eq record.attributes
    end
  end

  describe ".where(query)" do
    it "returns a Bodhi::Query object for querying Test resources" do
      query = Test.where("{test}")

      expect(query).to be_a Bodhi::Query
      expect(query.criteria).to include "{test}"
    end

    it "returns an Array of resources when called" do
      records = Test.factory.create_list(5, context, Olia: 20)
      other_records = Test.factory.create_list(5, context, Olia: 10)
      results = Test.where("{Olia: 20}").from(context).all

      puts "\033[33mFound Resources\033[0m: \033[36m#{results.map(&:attributes)}\033[0m"
      expect(results.count).to eq 5
      results.each{ |obj| expect(obj).to be_a Test }
      expect(JSON.parse(results.to_json)).to match_array JSON.parse(records.to_json)
    end
  end

  describe ".aggregate(context, pipeline)" do
    it "should raise error if context is not valid" do
      bad_context = Bodhi::Context.new({})
      expect{ Test.aggregate(bad_context, "test") }.to raise_error(Bodhi::ContextErrors, '["server is required", "namespace is required"]')
    end

    it "should raise api error if the pipeline is not valid" do
      expect{ Test.aggregate(context, "12345") }.to raise_error(Bodhi::ApiErrors)
    end

    it "should return the aggregation as json" do
      records = Test.factory.create_list(10, context, Olia: 20)
      other_records = Test.factory.create_list(5, context, Olia: 10)
      pipeline = "[
        { $match: { Olia: { $gte: 20 } } },
        { $group: { _id: 'count_olias_greater_than_20', Olia:{ $sum: 1 } } }
      ]"
      results = Test.aggregate(context, pipeline)

      puts "\033[33mAggregate Result\033[0m: \033[36m#{results}\033[0m"
      expect(results).to be_a Array
      results.each{ |obj| expect(obj).to be_a Hash }
      expect(results[0]["_id"]).to eq "count_olias_greater_than_20"
      expect(results[0]["Olia"]).to eq 10
    end
  end

  describe ".delete_all(context)" do
    it "raises Bodhi::ContextErrors if context is invalid" do
      bad_context = Bodhi::Context.new({})
      expect{ Test.delete_all(bad_context) }.to raise_error(Bodhi::ContextErrors, '["server is required", "namespace is required"]')
    end

    it "deletes all resources from the cloud in the given context" do
      Test.factory.create_list(5, context)
      expect(Test.find_all(context).size).to eq 5

      expect{ Test.delete_all(context) }.to_not raise_error
      expect(Test.find_all(context).size).to eq 0
    end
  end

  describe ".count(context)" do
    it "raises Bodhi::ContextErrors if context is invalid" do
      bad_context = Bodhi::Context.new({})
      expect{ Test.count(bad_context) }.to raise_error(Bodhi::ContextErrors, '["server is required", "namespace is required"]')
    end

    it "raises Bodhi::ApiErrors if not authorized" do
      bad_context = Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: nil })
      expect{ Test.count(bad_context) }.to raise_error(Bodhi::ApiErrors, 'status: 401, body: {"authentication.credentials.required":"Authentication failed","authentication.supported.types":"HTTP_COOKIE, HTTP_BASIC"}')
    end

    it "returns a JSON object with the record count" do
      Test.factory.create_list(5, context)
      result = Test.count(context)

      expect(result).to be_a Hash
      expect(result["count"]).to eq 5
    end
  end
end