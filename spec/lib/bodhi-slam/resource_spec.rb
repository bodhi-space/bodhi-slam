require 'spec_helper'

describe Bodhi::Resource do
  let(:context){ Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: ENV['QA_TEST_COOKIE'] }) }

  before do
    Object.const_set("TestResource", Class.new{ include Bodhi::Resource; attr_accessor :foo })
    FactoryGirl.define{ factory("TestResource"){ foo { "test" } } }

    Object.const_set("Test", Class.new{ include Bodhi::Resource; attr_accessor :Brandon, :Olia, :Alisa })
    FactoryGirl.define{ factory("Test"){ Brandon{ true }; Olia{ 1 }; Alisa{ "test" } } }
  end

  after do
    Test.delete_all(context)
    FactoryGirl.factories.clear
    Object.send(:remove_const, :TestResource)
    Object.send(:remove_const, :Test)
  end

  it "includes Bodhi::Validations" do
    expect(TestResource.ancestors).to include Bodhi::Validations
  end

  describe "#attributes" do
    it "returns the objects form attributes" do
      test = TestResource.build(context)
      expect(test.attributes).to have_key :foo
      expect(test.attributes[:foo]).to eq "test"
    end

    it "does not return the objects system attributes" do
      test = TestResource.build(context)
      expect(test.attributes.keys).to_not include(Bodhi::Resource::SYSTEM_ATTRIBUTES)
    end
  end

  describe "#save!" do
    it "should raise error if the object could not be saved" do
      test = Test.build(context)
      test.Olia = "1"
      expect{ test.save! }.to raise_error(ArgumentError, "something bad happened")
    end

    it "should POST the objects attributes to the cloud" do
      test = Test.build(context)
      expect{ test.save! }.to_not raise_error
    end
  end

  describe "#delete!" do
    it "raises error if the object could not be deleted" do
      record = Test.create(context)
      record.sys_id = nil
      expect{ record.delete! }.to raise_error(ArgumentError, "something bad happened")
    end

    it "should DELETE the object from the could" do
      record = Test.create(context)
      expect{ record.delete! }.to_not raise_error
    end
  end

  describe ".find(context, id)" do
    it "should raise error if context is not valid" do
      bad_context = Bodhi::Context.new({})
      expect{ Test.find(bad_context, "12345") }.to raise_error(ArgumentError, "something bad happened")
    end

    it "should raise api error if id is not present" do
      expect{ Test.find(context, "12345") }.to raise_error(ArgumentError, "something bad happened")
    end

    it "should return the resource with the given id" do
      record = Test.create(context)
      result = Test.find(context, record.sys_id)
      expect(result).to be_a Test

      puts "\033[33mFound Resource\033[0m: \033[36m#{result.attributes}\033[0m"
      expect(result.attributes).to eq record.attributes
    end
  end

  describe ".where(context, query)" do
    it "should raise error if context is not valid" do
      bad_context = Bodhi::Context.new({})
      expect{ Test.where(bad_context, "12345") }.to raise_error(ArgumentError, "something bad happened")
    end

    it "should raise api error if the query is not valid" do
      expect{ Test.where(context, "12345") }.to raise_error(ArgumentError, "something bad happened")
    end

    it "should return an array of resources that match the query" do
      records = Test.create_list(context, 5, {Olia: 20})
      other_records = Test.create_list(context, 5, {Olia: 10})
      results = Test.where(context, "{Olia: 20}")

      puts "\033[33mFound Resources\033[0m: \033[36m#{results.map(&:attributes)}\033[0m"
      expect(results.count).to eq 5
      results.each{ |obj| expect(obj).to be_a Test }
      expect(results.to_json).to eq records.to_json
    end
  end

  describe ".aggregate(context, pipeline)" do
    it "should raise error if context is not valid" do
      bad_context = Bodhi::Context.new({})
      expect{ Test.aggregate(bad_context, "12345") }.to raise_error(ArgumentError, "something bad happened")
    end

    it "should raise api error if the pipeline is not valid" do
      expect{ Test.aggregate(context, "12345") }.to raise_error(ArgumentError, "something bad happened")
    end

    it "should return the aggregation as json" do
      records = Test.create_list(context, 10, {Olia: 20})
      other_records = Test.create_list(context, 5, {Olia: 10})
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
    it "raises error if context is invalid" do
      bad_context = Bodhi::Context.new({})
      expect{ Test.delete_all(bad_context) }.to raise_error(ArgumentError, "something bad happened")
    end

    it "deletes all resources from the cloud within the given context"
  end

  describe ".build(context, params={})" do
    it "should return a new resource" do
      expect(TestResource.build(context)).to be_instance_of TestResource
    end

    it "should override any attributes with the supplied params hash" do
      record = TestResource.build(context, {foo: "foo"})
      expect(record.foo).to eq "foo"
    end
  end

  describe ".build_list(context, amount, params={})" do
    it "should return an array of new resources" do
      records = TestResource.build_list(context, 10)
      expect(records.count).to eq 10
      records.each{ |item| expect(item).to be_a TestResource }
      puts "\033[33mGenerated\033[0m: \033[36m#{records.map(&:attributes).to_s}\033[0m"
    end

    it "should override attributes for each resource from the supplied params hash" do
      records = TestResource.build_list(context, 10, { foo: "12345" })
      expect(records.count).to eq 10
      records.each{ |item| expect(item.foo).to eq "12345" }
      puts "\033[33mGenerated\033[0m: \033[36m#{records.map(&:attributes).to_s}\033[0m"
    end
  end

  describe ".create(context, params={})" do
    it "should create a new resource" do
      expect(Test.create(context)).to be_instance_of Test
    end

    it "should override any attributes with the supplied params hash" do
      record = Test.create(context, {Olia: 100})
      expect(record.Brandon).to eq true
      expect(record.Olia).to eq 100
      expect(record.Alisa).to eq "test"
    end

    it "raise RuntimeError if the resource could not be created" do
      expect{ Test.create(context, {Brandon: "test"}) }.to raise_error(ArgumentError, "something bad happened")
    end
  end

  describe ".create_list(context, amount, params={})" do
    it "should return an array of the created resources" do
      records = Test.create_list(context, 10)
      expect(records.count).to eq 10
      records.each{ |item| expect(item).to be_a Test }
      puts "\033[33mCreated\033[0m: \033[36m#{records.map(&:attributes).to_s}\033[0m"
    end

    it "should override attributes for each resource from the supplied params hash" do
      records = Test.create_list(context, 10, {Olia: 100})
      expect(records.count).to eq 10
      records.each do |item|
        expect(item).to be_a Test
        expect(item.Brandon).to eq true
        expect(item.Olia).to eq 100
        expect(item.Alisa).to eq "test"
      end
      puts "\033[33mCreated\033[0m: \033[36m#{records.map(&:attributes).to_s}\033[0m"
    end

    it "raise RuntimeError if any resource could not be created" do
      expect{ Test.create_list(context, 10, {Brandon: "test"}) }.to raise_error(ArgumentError, "something bad happened")
    end
  end
end