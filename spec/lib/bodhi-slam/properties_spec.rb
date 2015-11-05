require 'spec_helper'

describe Bodhi::Properties do
  let(:klass){ Class.new{ include Bodhi::Properties } }

  describe "SYSTEM_PROPERTIES" do
    it "is an array of all Bodhi system properties" do
      expect(Bodhi::Properties::SYSTEM_PROPERTIES).to include :sys_created_at, :sys_version, :sys_modified_at, :sys_modified_by,
      :sys_namespace, :sys_created_by, :sys_type_version, :sys_id, :sys_embeddedType
    end
  end

  describe ".property(*names)" do
    it "adds a new property with the given name (string)" do
      expect{klass.property "test"}.to_not raise_error
      expect(klass.properties).to include :test
    end

    it "adds a new property with the given name (symbol)" do
      expect{klass.property :test}.to_not raise_error
      expect(klass.properties).to include :test
    end

    it "adds multiple properties from the given array of names" do
      expect{klass.property :test, :foo, :bar}.to_not raise_error
      expect(klass.properties).to include :test, :foo, :bar
    end
  end

  describe ".properties" do
    it "returns an Array of all properties for the class" do
      expect(klass.properties).to be_a Array
    end
  end

  describe "#initialize(params={})" do
    it "returns a new object with the given params" do
      klass.property :name
      object = klass.new(name: "test")
      expect(object.name).to eq "test"
    end
  end

  describe "#attributes" do
    it "returns a Hash of the objects properties and values" do
      klass.property :name
      object = klass.new(name: "test")
      expect(object.attributes).to eq name: "test"
    end
  end

  describe "#update_attributes(params)" do
    it "updates the object with the given params" do
      klass.property :name, :email
      object = klass.new(name: "test", email: "test@email.com")
      object.update_attributes(name: "foo")
      expect(object.attributes).to eq name: "foo", email: "test@email.com"
    end
  end

  describe "#to_json" do
    it "returns a JSON string of the objects attributes" do
      klass.property :name
      object = klass.new(name: "test")
      expect(object.to_json).to eq '{"name":"test"}'
    end
  end

  describe "#id" do
    it "returns the system id of the object" do
      object = klass.new
      object.sys_id = "test"
      expect(object.id).to eq "test"
    end
  end

  describe "#persisted?" do
    it "returns true if the object has a value for the sys_id property" do
      object = klass.new
      object.sys_id = "test"
      expect(object.persisted?).to be true
    end

    it "returns false if the object does not have a value for the sys_id property" do
      object = klass.new
      expect(object.persisted?).to be false
    end
  end

  describe "#new_record?" do
    it "returns true if the object does not have a value for the sys_id property" do
      object = klass.new
      expect(object.new_record?).to be true
    end

    it "returns false if the object has a value for the sys_id property" do
      object = klass.new
      object.sys_id = "test"
      expect(object.new_record?).to be false
    end
  end
end