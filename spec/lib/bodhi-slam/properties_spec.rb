require 'spec_helper'

describe Bodhi::Properties do
  let(:klass){ Class.new{ include Bodhi::Properties } }

  describe "SYSTEM_PROPERTIES" do
    it "is an array of all Bodhi system properties" do
      expect(Bodhi::Properties::SYSTEM_PROPERTIES).to include :sys_created_at, :sys_version, :sys_modified_at, :sys_modified_by,
      :sys_namespace, :sys_created_by, :sys_type_version, :sys_id, :sys_embeddedType
    end
  end

  describe ".property(name, options)" do
    it "adds a new property with the given name (string)" do
      expect{klass.property "test", type: String}.to_not raise_error
      expect(klass.properties).to include :test
    end

    it "adds a new property with the given name (symbol)" do
      expect{klass.property :test, type: "String"}.to_not raise_error
      expect(klass.properties).to include :test
    end
  end

  describe ".properties" do
    it "returns an Array of all properties for the class" do
      expect(klass.properties).to be_a Hash
    end
  end

  describe "#initialize(options={})" do
    it "returns a new object with the given options" do
      klass.property :name, type: String
      klass.property :address, type: "String"

      object = klass.new(name: "test")

      expect(object.name).to eq "test"
      expect(object.address).to eq nil
    end

    context "type coersion" do
      it "converts from String to Time" do
        klass.property :date, type: "DateTime"

        object = klass.new(date: "November 3rd 2011 10:26pm")

        expect(object.date).to be_a Time
        expect(object.date).to eq Time.parse("November 3rd 2011 10:26pm")
      end

      it "converts from String to Integer" do
        klass.property :date, type: "Integer"

        object = klass.new(date: "-12345")

        expect(object.date).to be_a Integer
        expect(object.date).to eq -12345
      end

      it "converts from String to Decimal (Real)" do
        klass.property :date, type: "Real"

        object = klass.new(date: "10.55")

        expect(object.date).to be_a Float
        expect(object.date).to eq 10.55
      end

      it "converts Hash to an object of the properties type" do
        klass2 = Object.const_set("AwesomeType", Class.new{ include Bodhi::Properties })

        klass2.property :name, type: String
        klass.property :embedded, type: AwesomeType

        object = klass.new("embedded" => { "name" => "Dogmeat" })

        expect(object.embedded).to be_a AwesomeType
        expect(object.embedded.name).to eq "Dogmeat"

        Object.send(:remove_const, :AwesomeType)
      end
    end
  end

  describe "#attributes" do
    it "returns a Hash of the objects properties and values" do
      klass.property :name, type: String
      klass.property :age, type: Integer

      object = klass.new(name: "test", age: 42)
      expect(object.attributes).to eq name: "test", age: 42
    end

    it "serializes embedded resources to a hash" do
      klass2 = Object.const_set("AwesomeType", Class.new{ include Bodhi::Properties })
      klass2.property :test, type: String
      klass.property :name, type: AwesomeType

      object = klass.new(name: { test: "hello" })
      expect(object.attributes).to eq name: { test: "hello" }

      Object.send(:remove_const, :AwesomeType)
    end

    it "serializes arrays of embedded resources to an array of hashes" do
      klass2 = Object.const_set("AwesomeType", Class.new{ include Bodhi::Properties })
      klass2.property :test, type: String

      klass.property :name, type: AwesomeType, multi: true
      object = klass.new(name: [{ test: "hello"}, { test: "foo" }, { test: "bar" }])
      expect(object.attributes).to eq name: [{ test: "hello" }, { test: "foo" }, { test: "bar" }]

      Object.send(:remove_const, :AwesomeType)
    end
  end

  describe "#update_attributes(params)" do
    it "updates the object with the given params" do
      klass.property :name, type: String
      klass.property :email, type: String

      object = klass.new(name: "test", email: "test@email.com")
      object.update_attributes(name: "foo")

      expect(object.attributes).to eq name: "foo", email: "test@email.com"
    end
  end

  describe "#to_json" do
    it "returns a JSON string of the objects attributes" do
      klass.property :name, type: String
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