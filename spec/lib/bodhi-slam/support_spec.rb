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
end