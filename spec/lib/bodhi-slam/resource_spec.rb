require 'spec_helper'

describe Bodhi::Resource do

  before do
    Object.const_set("TestResource", Class.new{ include Bodhi::Resource; attr_accessor :foo })
    FactoryGirl.define{ factory("TestResource"){ foo { "test" } } }
  end

  after do
    Object.send(:remove_const, :TestResource)
    FactoryGirl.factories.clear
  end

  it "includes Bodhi::Validations" do
    expect(TestResource.ancestors).to include Bodhi::Validations
  end

  describe ".build(params={})" do
    it "should return a new resource" do
      expect(TestResource.build).to be_instance_of TestResource
    end

    it "should override any attributes with the supplied params hash" do
      record = TestResource.build({foo: "foo"})
      expect(record.foo).to eq "foo"
    end
  end

  describe ".build_list(amount, params={})" do
    it "should return an array of new resources" do
      records = TestResource.build_list(10)
      expect(records.count).to eq 10
      records.each{ |item| expect(item).to be_a TestResource }
    end

    it "should override attributes for each resource from the supplied params hash" do
      records = TestResource.build_list(10, { foo: "12345" })
      expect(records.count).to eq 10
      records.each{ |item| expect(item.foo).to eq "12345" }
    end
  end

  describe ".create(params={})" do
    it "should create a new resource"
    it "should override any attributes with the supplied params hash"
    it "raise RuntimeError if the resource could not be created"
  end

  describe ".create_list(amount, params={})" do
    it "should return an array of the created resources"
    it "should override attributes for each resource from the supplied params hash"
    it "raise RuntimeError if any resource could not be created"
  end
end