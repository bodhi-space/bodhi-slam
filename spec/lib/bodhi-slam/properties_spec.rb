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
      it "converts to String using :to_s" do
        klass.property :string, type: "String"
        klass.property :string_array, type: "String", multi: true

        object = klass.new(string: 10.55)
        object2 = klass.new(string_array: [10.55, "foo", true])

        expect(object.string).to be_a String
        expect(object.string).to eq "10.55"

        expect(object2.string_array).to be_a Array
        object2.string_array.each{ |item| expect(item).to be_a String }
      end

      it "converts to Time using Time.parse()" do
        klass.property :date, type: "DateTime"
        klass.property :date_array, type: "DateTime", multi: true

        object = klass.new(date: "November 3rd 2011 10:26pm")
        object2 = klass.new(date_array: ["November 3rd 2011 10:26pm", "12-10-1910"])

        expect(object.date).to be_a Time
        expect(object.date).to eq Time.parse("November 3rd 2011 10:26pm")

        expect(object2.date_array).to be_a Array
        object2.date_array.each{ |item| expect(item).to be_a Time }
      end

      it "converts to Integer using :to_i" do
        klass.property :integer, type: "Integer"
        klass.property :integer_array, type: "Integer", multi: true

        object = klass.new(integer: "-12345")
        object2 = klass.new(integer_array: ["-12345", 10101])

        expect(object.integer).to be_a Integer
        expect(object.integer).to eq -12345

        expect(object2.integer_array).to be_a Array
        object2.integer_array.each{ |item| expect(item).to be_a Integer }
      end

      it "converts to Float (Real) using :to_f" do
        klass.property :float, type: "Real"
        klass.property :float_array, type: "Real", multi: true

        object = klass.new(float: "10.55")
        object2 = klass.new(float_array: ["10.0", 3.99])

        expect(object.float).to be_a Float
        expect(object.float).to eq 10.55

        expect(object2.float_array).to be_a Array
        object2.float_array.each{ |item| expect(item).to be_a Float }
      end

      it "converts Hash to an object of the properties type" do
        klass2 = Object.const_set("AwesomeType", Class.new{ include Bodhi::Properties })

        klass2.property :name, type: String
        klass.property :embedded, type: AwesomeType
        klass.property :embedded_array, type: AwesomeType, multi: true

        object = klass.new("embedded" => { "name" => "Dogmeat" })
        object2 = klass.new(embedded_array: [{ name: "Jet"}, { "name" => "Psycho"}])

        expect(object.embedded).to be_a AwesomeType
        expect(object.embedded.name).to eq "Dogmeat"

        expect(object2.embedded_array).to be_a Array
        object2.embedded_array.each{ |item| expect(item).to be_a AwesomeType }

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