require 'spec_helper'

describe Bodhi::Resource do
  before(:all) do
    @context = Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: ENV['QA_TEST_COOKIE'] })
    @type = Bodhi::Type.new(name: "TestResource", properties: { foo: { type: "String" }, bar: { type: "TestEmbeddedResource" }, baz: { type: "Integer" } })
    @embedded_type = Bodhi::Type.new(name: "TestEmbeddedResource", properties: { test: { type: "String" }, bool: { type: "Boolean" } }, embedded: true)

    @type.bodhi_context = @context
    @embedded_type.bodhi_context = @context

    @type.save!
    @embedded_type.save!

    Bodhi::Type.create_class_with(@type)
    Bodhi::Type.create_class_with(@embedded_type)
  end

  after(:all) do
    @type.delete!
    @embedded_type.delete!

    Object.send(:remove_const, :TestResource)
    Object.send(:remove_const, :TestEmbeddedResource)
  end

  after do
    TestResource.delete_all(@context)
  end

  it "includes Bodhi::Validations" do
    expect(TestResource.ancestors).to include Bodhi::Validations
  end

  describe "#initialize(params)" do
    it "returns a new resource instance" do
      test = TestResource.new
      expect(test).to be_a TestResource
    end

    it "returns a new resource instance with the given params (symbols as keys)" do
      test = TestResource.new(foo: "hello", bar: { test: "test", bool: true }, baz: 10)

      expect(test).to be_a TestResource
      expect(test.foo).to eq "hello"
      expect(test.baz).to eq 10
      expect(test.bar).to be_a TestEmbeddedResource
      expect(test.bar.test).to eq "test"
      expect(test.bar.bool).to eq true
    end

    it "returns a new resource instance with the given params (strings as keys)" do
      test = TestResource.new("foo" => "hello", "bar" => { "test" => "test", "bool" => true }, "baz" => 10)

      expect(test).to be_a TestResource
      expect(test.foo).to eq "hello"
      expect(test.baz).to eq 10
      expect(test.bar).to be_a TestEmbeddedResource
      expect(test.bar.test).to eq "test"
      expect(test.bar.bool).to eq true
    end
  end

  describe "#attributes" do
    it "returns the objects form attributes" do
      test = TestResource.factory.build
      expect(test.attributes).to have_key :foo
      expect(test.attributes[:foo]).to be_a String
    end

    it "does not return the objects system attributes" do
      test = TestResource.factory.build
      expect(test.attributes.keys).to_not include(Bodhi::Properties::SYSTEM_PROPERTIES)
    end

    it "does not return the objects :bodhi_context attribute" do
      test = TestResource.factory.build
      expect(test.attributes.keys).to_not include :bodhi_context
    end

    it "does not return the objects :errors attribute" do
      test = TestResource.factory.build
      expect(test.attributes.keys).to_not include :errors
    end
  end

  describe "#save" do
    it "uses the Bodhi::Context.global_context if no context is present" do
      Bodhi::Context.global_context = @context
      test = TestResource.new(foo: "hello world", bar: { test: "abcd", bool: true })
      expect(test.save).to be true
      Bodhi::Context.global_context = nil
    end

    it "raises Bodhi::ContextErrors if the context is not valid" do
      bad_context = Bodhi::Context.new
      test = TestResource.new(foo: "hello world", bodhi_context: bad_context)
      expect{ test.save }.to raise_error(Bodhi::ContextErrors)
    end

    it "returns false if the record is not valid" do
      test = TestResource.new(foo: 12345, bodhi_context: @context)
      expect(test.save).to be false
    end

    it "returns true if the record was posted to the cloud" do
      test = TestResource.new(foo: "hello world", bodhi_context: @context)
      expect(test.save).to be true
    end

    it "raises Bodhi::ApiErrors if the record can not post to the cloud"
  end

  describe "#save!" do
    it "should raise Bodhi::ApiErrors if the object could not be saved" do
      test = TestResource.factory.build(foo: 12345)
      test.bodhi_context = @context
      expect{ test.save! }.to raise_error(Bodhi::ApiErrors)
    end

    it "should POST the objects attributes to the cloud" do
      test = TestResource.factory.build
      test.bodhi_context = @context
      expect{ test.save! }.to_not raise_error
    end
  end

  describe "#delete!" do
    it "raises Bodhi::ApiErrors if the object could not be deleted" do
      record = TestResource.factory.create(@context)
      record.sys_id = nil
      expect{ record.delete! }.to raise_error(Bodhi::ApiErrors)
    end

    it "should DELETE the object from the cloud" do
      record = TestResource.factory.create(@context)
      expect{ record.delete! }.to_not raise_error
    end
  end

  describe "#patch!(params)" do
    it "raises Bodhi::ApiErrors if the object could not be patched" do
      record = TestResource.factory.create(@context)
      expect{ record.patch!([{}]) }.to raise_error(Bodhi::ApiErrors)
    end

    it "updates the record with the given patch arguments" do
      record = TestResource.factory.create(@context)
      record.patch!([{ op: "replace", path: "/foo", value: "hello world" }])
      record.patch!([{ op: "replace", path: "/bar/test", value: "hello world" }])

      result = TestResource.find(record.id, @context)
      expect(result.foo).to eq "hello world"
      expect(result.bar.test).to eq "hello world"
    end
  end

  describe ".build_type" do
    it "returns a Bodhi::Type based on the classes properties and validations" do
      klass = Object.const_set("TestResource12345", Class.new do
        include Bodhi::Resource
        field :name, type: "String", required: true
        field :email, type: "String", is_email: true

        index [:name], unique: true
      end)

      type = klass.build_type

      expect(type).to be_a Bodhi::Type
      expect(type.name).to eq "TestResource12345"
      expect(type.properties).to eq name: { type: "String", required: true }, email: { type: "String", isEmail: true }
      expect(type.indexes.first.keys).to eq ["name"]
      expect(type.indexes.first.options).to eq unique: true
      expect(type.to_json).to eq '{"name":"TestResource12345","properties":{"name":{"type":"String","required":true},"email":{"type":"String","isEmail":true}},"indexes":[{"keys":["name"],"options":{"unique":true}}]}'

      Object.send(:remove_const, :TestResource12345)
    end

    it "builds a valid Bodhi::Type that can be saved to the cloud" do
      klass = Object.const_set("TestResource12345", Class.new do
        include Bodhi::Resource
        field :name, type: "String", required: true
        field :email, type: "String", is_email: true

        index [:name], unique: true
      end)

      type = klass.build_type
      type.bodhi_context = @context

      type.valid?
      expect(type.errors.to_a).to be_empty
      expect{ type.save! }.to_not raise_error
      expect{ type.delete! }.to_not raise_error

      Object.send(:remove_const, :TestResource12345)
    end
  end

  describe ".save_batch(context, records)" do
    it "saves and returns a batch of the records" do
      records = [TestResource.factory.build, TestResource.factory.build]
      result = TestResource.save_batch(@context, records)
      expect(result).to be_a Bodhi::ResourceBatch
      expect(result.failed).to be_empty
      expect(result.created).to match_array(records)
    end
  end

  describe ".find(id, context=nil)" do
    it "should raise Bodhi::Error if context is not valid" do
      bad_context = Bodhi::Context.new({})
      expect{ TestResource.find(1234, bad_context) }.to raise_error(Bodhi::ContextErrors, '["server is required", "namespace is required"]')
    end

    it "should raise Bodhi::ApiErrors if :id is not present" do
      expect{ TestResource.find("12345", @context) }.to raise_error(Bodhi::ApiErrors)
    end

    it "should return the resource with the given id" do
      record = TestResource.factory.create(@context)
      result = TestResource.find(record.sys_id, @context)
      expect(result).to be_a TestResource

      puts "\033[33mFound Resource\033[0m: \033[36m#{result.attributes}\033[0m"
      expect(result.to_json).to eq record.to_json
    end
  end

  describe ".where(query)" do
    it "returns a Bodhi::Query object for querying Test resources" do
      query = TestResource.where("{test}")

      expect(query).to be_a Bodhi::Query
      expect(query.criteria).to include "{test}"
    end

    it "returns an Array of resources when called" do
      records = TestResource.factory.create_list(5, @context, foo: "test")
      other_records = TestResource.factory.create_list(5, @context, foo: "not_test")
      results = TestResource.where("{foo: 'test'}").from(@context).all

      puts "\033[33mFound Resources\033[0m: \033[36m#{results.map(&:attributes)}\033[0m"
      expect(results.count).to eq 5
      results.each{ |obj| expect(obj).to be_a TestResource }
      expect(JSON.parse(results.to_json)).to match_array JSON.parse(records.to_json)
    end
  end

  describe ".aggregate(context, pipeline)" do
    it "should raise error if context is not valid" do
      bad_context = Bodhi::Context.new({})
      expect{ TestResource.aggregate(bad_context, "test") }.to raise_error(Bodhi::ContextErrors, '["server is required", "namespace is required"]')
    end

    it "should raise api error if the pipeline is not valid" do
      expect{ TestResource.aggregate(@context, "12345") }.to raise_error(Bodhi::ApiErrors)
    end

    it "should return the aggregation as json" do
      records = TestResource.factory.create_list(10, @context, baz: 20)
      other_records = TestResource.factory.create_list(5, @context, baz: 10)
      pipeline = "[
        { $match: { baz: { $gte: 20 } } },
        { $group: { _id: 'count_baz_greater_than_20', baz:{ $sum: 1 } } }
      ]"
      results = TestResource.aggregate(@context, pipeline)

      puts "\033[33mAggregate Result\033[0m: \033[36m#{results}\033[0m"
      expect(results).to be_a Array
      results.each{ |obj| expect(obj).to be_a Hash }
      expect(results[0]["_id"]).to eq "count_baz_greater_than_20"
      expect(results[0]["baz"]).to eq 10
    end
  end

  describe ".delete_all(context)" do
    it "raises Bodhi::ContextErrors if context is invalid" do
      bad_context = Bodhi::Context.new({})
      expect{ TestResource.delete_all(bad_context) }.to raise_error(Bodhi::ContextErrors, '["server is required", "namespace is required"]')
    end

    it "deletes all resources from the cloud in the given context" do
      TestResource.factory.create_list(5, @context)
      expect(TestResource.find_all(@context).size).to eq 5

      expect{ TestResource.delete_all(@context) }.to_not raise_error
      expect(TestResource.find_all(@context).size).to eq 0
    end
  end

  describe ".count(context)" do
    it "raises Bodhi::ContextErrors if context is invalid" do
      bad_context = Bodhi::Context.new({})
      expect{ TestResource.count(bad_context) }.to raise_error(Bodhi::ContextErrors, '["server is required", "namespace is required"]')
    end

    it "raises Bodhi::ApiErrors if not authorized" do
      bad_context = Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: nil })
      expect{ TestResource.count(bad_context) }.to raise_error(Bodhi::ApiErrors)
    end

    it "returns a JSON object with the record count" do
      TestResource.factory.create_list(5, @context)
      result = TestResource.count(@context)

      expect(result).to be_a Hash
      expect(result["count"]).to eq 5
    end
  end
end