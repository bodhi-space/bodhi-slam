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

    context "from a Hash" do
      it "returns a new object (String Keys)" do
        klass.property :name, type: String
        object = klass.new("name" => "test")
        expect(object.name).to eq "test"
      end

      it "returns a new object (Symbol Keys)" do
        klass.property :name, type: String
        object = klass.new(name: "test")
        expect(object.name).to eq "test"
      end
    end

    context "from a JSON String" do
      it "returns a new object" do
        klass.property :name, type: String
        object = klass.new('{"name":"test"}')
        expect(object.name).to eq "test"
      end

      it "raises JSON::ParseError if the String is not valid JSON" do
        klass.property :name, type: String
        expect{ klass.new('"name":"test"') }.to raise_error(JSON::ParserError)
      end
    end

    context "embedded objects" do
      it "from Hash, returns a new object with all embedded objects" do
        klass2 = Object.const_set("AwesomeType", Class.new{ include Bodhi::Properties })
        klass2.property :test, type: String
        klass.property :name, type: AwesomeType

        object = klass.new(name: { test: "hello" })
        expect(object.name).to be_a AwesomeType
        expect(object.name.test).to eq "hello"

        Object.send(:remove_const, :AwesomeType)
      end

      it "from Object, returns a new object with all embedded objects" do
        klass2 = Object.const_set("AwesomeType", Class.new{ include Bodhi::Properties })
        klass2.property :test, type: String
        klass.property :name, type: AwesomeType

        object = klass.new(name: AwesomeType.new(test: "hello"))
        expect(object.name).to be_a AwesomeType
        expect(object.name.test).to eq "hello"

        Object.send(:remove_const, :AwesomeType)
      end
    end

    context "arrays of embedded objects" do
      it "from Hash, returns a new object with all embedded objects" do
        klass2 = Object.const_set("AwesomeType", Class.new{ include Bodhi::Properties })
        klass2.property :test, type: String
        klass.property :name, type: AwesomeType, multi: true

        object = klass.new(name: [{ test: "hello" }, { test: "Dirty Wastelander" }])
        expect(object.name).to be_a Array
        object.name.each{ |item| expect(item).to be_a AwesomeType }

        Object.send(:remove_const, :AwesomeType)
      end

      it "from Object, returns a new object with all embedded objects" do
        klass2 = Object.const_set("AwesomeType", Class.new{ include Bodhi::Properties })
        klass2.property :test, type: String
        klass.property :name, type: AwesomeType, multi: true

        object = klass.new(name: [AwesomeType.new(test: "hello"), AwesomeType.new(test: "Radroach")])
        expect(object.name).to be_a Array
        object.name.each{ |item| expect(item).to be_a AwesomeType }

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