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
    it "should raise error if the object could not be saved"

    it "should POST the objects attributes to the cloud" do
      test = Test.factory.build
      test.bodhi_context = context
      expect{ test.save! }.to_not raise_error
    end
  end

  describe "#delete!" do
    it "raises error if the object could not be deleted"

    it "should DELETE the object from the could" do
      record = Test.factory.create(context)
      expect{ record.delete! }.to_not raise_error
    end
  end

  describe ".find(context, id)" do
    it "should raise error if context is not valid"
    it "should raise api error if id is not present"

    it "should return the resource with the given id" do
      record = Test.factory.create(context)
      result = Test.find(context, record.sys_id)
      expect(result).to be_a Test

      puts "\033[33mFound Resource\033[0m: \033[36m#{result.attributes}\033[0m"
      expect(result.attributes).to eq record.attributes
    end
  end

  describe ".where(context, query)" do
    it "should raise error if context is not valid"
    it "should raise api error if the query is not valid"

    it "should return an array of resources that match the query" do
      records = Test.factory.create_list(5, context, Olia: 20)
      other_records = Test.factory.create_list(5, context, Olia: 10)
      results = Test.where(context, "{Olia: 20}")

      puts "\033[33mFound Resources\033[0m: \033[36m#{results.map(&:attributes)}\033[0m"
      expect(results.count).to eq 5
      results.each{ |obj| expect(obj).to be_a Test }
      expect(JSON.parse(results.to_json)).to match_array JSON.parse(records.to_json)
    end
  end

  describe ".aggregate(context, pipeline)" do
    it "should raise error if context is not valid"
    it "should raise api error if the pipeline is not valid"

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
    it "raises error if context is invalid"
    it "deletes all resources from the cloud within the given context"
  end
end