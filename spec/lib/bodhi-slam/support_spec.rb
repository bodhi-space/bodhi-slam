require 'spec_helper'

describe Bodhi::Support do
  describe ".underscore(string)" do
    it "converts dash (-) to underscore (_)" do
      expect(Bodhi::Support.underscore("test-test")).to eq "test_test"
    end

    it "converts the given string to snake_case (from: CamelCase)" do
      expect(Bodhi::Support.underscore("ToSnakeCase")).to eq "to_snake_case"
    end

    it "converts the given string to snake_case (from: reverseCamelCase)" do
      expect(Bodhi::Support.underscore("toSnakeCase")).to eq "to_snake_case"
    end

    it "converts the given string to snake_case (from: snake_case)" do
      expect(Bodhi::Support.underscore("to_snake_case")).to eq "to_snake_case"
    end

    it "handles weird combinations of characters" do
      expect(Bodhi::Support.underscore("FOO")).to eq "foo"
      expect(Bodhi::Support.underscore("JSONObject")).to eq "json_object"
      expect(Bodhi::Support.underscore("test!@#$%^&*()-12345_TEST")).to eq "test!@#$%^&*()_12345_test"
    end
  end

  describe ".camelize(string)" do
    it "converts the given string to CamelCase (from: CamelCase)" do
      expect(Bodhi::Support.camelize("ToCamelCase")).to eq "ToCamelCase"
    end

    it "converts the given string to CamelCase (from: reverseCamelCase)" do
      expect(Bodhi::Support.camelize("toCamelCase")).to eq "ToCamelCase"
    end

    it "converts the given string to CamelCase (from: snake_case)" do
      expect(Bodhi::Support.camelize("to_camel_case")).to eq "ToCamelCase"
    end

    it "handles weird combinations of characters" do
      expect(Bodhi::Support.camelize("FOO")).to eq "Foo"
      expect(Bodhi::Support.camelize("JSONObject")).to eq "JsonObject"
      expect(Bodhi::Support.camelize("test!@#$%^&*()")).to eq "Test!@#$%^&*()"
    end
  end

  describe ".reverse_camelize(string)" do
    it "converts the given string to reverseCamelCase (from: CamelCase)" do
      expect(Bodhi::Support.reverse_camelize("ReverseCamelCase")).to eq "reverseCamelCase"
    end

    it "converts the given string to reverseCamelCase (from: reverseCamelCase)" do
      expect(Bodhi::Support.reverse_camelize("reverseCamelCase")).to eq "reverseCamelCase"
    end

    it "converts the given string to reverseCamelCase (from: snake_case)" do
      expect(Bodhi::Support.reverse_camelize("reverse_camel_case")).to eq "reverseCamelCase"
    end

    it "handles weird combinations of characters" do
      expect(Bodhi::Support.reverse_camelize("FOO")).to eq "foo"
      expect(Bodhi::Support.reverse_camelize("JSONObject")).to eq "jsonObject"
      expect(Bodhi::Support.reverse_camelize("test!@#$%^&*()")).to eq "test!@#$%^&*()"
    end
  end

  describe ".uncapitalize(string)" do
    it "returns the given string with the first character downcased" do
      expect(Bodhi::Support.uncapitalize("FOO")).to eq "fOO"
      expect(Bodhi::Support.uncapitalize("foo")).to eq "foo"
    end
  end

  describe ".symbolize_keys(hash)" do
    it "is ok with nulls" do
      hash = { "name" => nil }
      expect(Bodhi::Support.symbolize_keys(hash)).to eq name: nil
    end

    it "updates all of the keys to symbols" do
      hash = { "name" => "test" }
      expect(Bodhi::Support.symbolize_keys(hash)).to eq name: "test"
    end

    it "updates any child hash's keys to symbols" do
      hash = { "name" => { "test" => { "inception" => true } } }
      expect(Bodhi::Support.symbolize_keys(hash)).to eq name: { test: { inception: true } }
    end

    it "updates any array hashes to have symbols as keys" do
      hash = { "name" => [ { "test" => "12345" }, { "foo" => true } ] }
      expect(Bodhi::Support.symbolize_keys(hash)).to eq name: [{ test: "12345" }, { foo: true }]
    end
  end

  describe ".coerce(value, options)" do
    it "does not try to coerce nil values" do
      value = Bodhi::Support.coerce(nil, type: DateTime, multi: true)
      expect(value).to eq nil
    end

    it "converts to String" do
      value = Bodhi::Support.coerce(10, type: "String")
      value2 = Bodhi::Support.coerce([10, 5.5, true], type: "String", multi: true)

      expect(value).to be_a String
      expect(value).to eq "10"

      expect(value2).to be_a Array
      expect(value2).to eq ["10", "5.5", "true"]
    end

    it "converts to Time" do
      value = Bodhi::Support.coerce("November 3rd 2011 10:26pm", type: "DateTime")
      value2 = Bodhi::Support.coerce(["November 3rd 2011 10:26pm", "12-10-1910"], type: "DateTime", multi: true)

      expect(value).to be_a Time
      expect(value).to eq Time.parse("November 3rd 2011 10:26pm")

      expect(value2).to be_a Array
      expect(value2).to eq [Time.parse("November 3rd 2011 10:26pm"), Time.parse("12-10-1910")]
    end

    it "converts to Integer" do
      value = Bodhi::Support.coerce("10", type: "Integer")
      value2 = Bodhi::Support.coerce(["10", 5.5], type: "Integer", multi: true)

      expect(value).to be_a Integer
      expect(value).to eq 10

      expect(value2).to be_a Array
      expect(value2).to eq [10, 5]
    end

    it "converts to Float (Real)" do
      value = Bodhi::Support.coerce("10.25", type: "Real")
      value2 = Bodhi::Support.coerce(["10.99", 5], type: "Real", multi: true)

      expect(value).to be_a Float
      expect(value).to eq 10.25

      expect(value2).to be_a Array
      expect(value2).to eq [10.99, 5.0]
    end

    it "converts Hash to an object of the properties type" do
      klass = Object.const_set("AwesomeType", Class.new{ include Bodhi::Properties })
      klass.property :name, type: "String"
      klass.property :embedded, type: "EmbeddedAwesomeType"

      klass2 = Object.const_set("EmbeddedAwesomeType", Class.new{ include Bodhi::Properties })
      klass2.property :name, type: "String"

      value = Bodhi::Support.coerce({"embedded" => { "name" => "Dogmeat" }}, type: "AwesomeType")
      value2 = Bodhi::Support.coerce([{ name: "Jet"}, { "name" => "Psycho"}], type: "AwesomeType", multi: true)

      expect(value).to be_a AwesomeType
      expect(value.embedded.name).to eq "Dogmeat"

      expect(value2).to be_a Array
      value2.each{ |item| expect(item).to be_a AwesomeType }

      Object.send(:remove_const, :AwesomeType)
      Object.send(:remove_const, :EmbeddedAwesomeType)
    end
  end
end