require 'spec_helper'

describe Bodhi::TypeValidator do
  let(:validator){ Bodhi::TypeValidator.new("MyClass", "Reference.name") }

  describe "#type" do
    it "is a String" do
      expect(validator.type).to eq "MyClass"
    end
  end

  describe "#reference" do
    it "is a String" do
      expect(validator.reference).to eq "Reference.name"
    end
  end
  
  describe "#to_options" do
    it "should return a Hash" do
      expect(validator.to_options).to be { type:"MyClass",ref:"Reference.name" }
    end
  end

  describe "#validate(record, attribute, value)" do
    let(:validator){ Bodhi::TypeValidator.new("String") }
    let(:klass) do
      Class.new do
        include Bodhi::Validations
        attr_accessor :foo
      end
    end
    let(:record){ klass.new }

    it "should not add errors if :value is nil" do
      record.foo = nil
      validator.validate(record, :foo, record.foo)
      expect(record.errors.full_messages).to be_empty
    end

    it "should not add errors if :value is an empty array" do
      record.foo = []
      validator.validate(record, :foo, record.foo)
      expect(record.errors.full_messages).to be_empty
    end

    context "when :attribute is a String" do
      let(:validator){ Bodhi::TypeValidator.new("String") }

      it "should validate a single object" do
        record.foo = 1234
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must be a String")
      end

      it "should validate arrays of objects" do
        record.foo = ["test", 12345]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must contain only Strings")

        record.errors.clear
        record.foo = ["test", "test"]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to be_empty
      end
    end

    context "when :attribute is a Integer" do
      let(:validator){ Bodhi::TypeValidator.new("Integer") }

      it "should validate a single object" do
        record.foo = "12345"
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must be a Integer")
      end

      it "should validate arrays of objects" do
        record.foo = [10.5, "test"]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must contain only Integers")

        record.errors.clear
        record.foo = [1,2,3,4]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to be_empty
      end
    end

    context "when :attribute is a Real" do
      let(:validator){ Bodhi::TypeValidator.new("Real") }

      it "should validate a single object" do
        record.foo = "12345"
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must be a Real")

        record.errors.clear
        record.foo = 10.5
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to be_empty
      end

      it "should validate arrays of objects" do
        record.foo = [10.5, 5]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must contain only Reals")

        record.errors.clear
        record.foo = [1.0, 2.5, 3.14, 9.99]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to be_empty
      end
    end

    context "when :attribute is a DateTime" do
      let(:validator){ Bodhi::TypeValidator.new("DateTime") }

      it "should validate a single object" do
        record.foo = 12345
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must be a DateTime")

        record.errors.clear
        record.foo = "1992-10-31"
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to be_empty
      end

      it "should validate arrays of objects" do
        record.foo = ["1992-10-31", "test"]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must contain only DateTimes")

        record.errors.clear
        record.foo = ["1992-10-31", "1992-06-14"]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to be_empty
      end
    end

    context "when :attribute is a Boolean" do
      let(:validator){ Bodhi::TypeValidator.new("Boolean") }

      it "should validate a single object" do
        record.foo = "12345"
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must be a Boolean")

        record.errors.clear
        record.foo = true
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to be_empty
      end

      it "should validate arrays of objects" do
        record.foo = [false, 5]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must contain only Booleans")

        record.errors.clear
        record.foo = [true, false, true, false]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to be_empty
      end
    end

    context "when :attribute is a GeoJSON" do
      let(:validator){ Bodhi::TypeValidator.new("GeoJSON") }

      it "should validate a single object" do
        record.foo = "12345"
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must be a GeoJSON")

        record.errors.clear
        record.foo = {}
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to be_empty
      end

      it "should validate arrays of objects" do
        record.foo = [{}, "test"]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must contain only GeoJSONs")

        record.errors.clear
        record.foo = [{}, {}, {}]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to be_empty
      end
    end

    context "when :attribute is a JSON Object" do
      let(:validator){ Bodhi::TypeValidator.new("Object") }

      it "should validate a single object" do
        record.foo = "12345"
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must be a JSON object")

        record.errors.clear
        record.foo = {}
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to be_empty
      end

      it "should validate arrays of objects" do
        record.foo = [{}, "test"]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must contain only JSON objects")

        record.errors.clear
        record.foo = [{}, {}, {}]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to be_empty
      end
    end

    context "when :attribute is Enumerated" do
      let(:validator){ Bodhi::TypeValidator.new("Enumerated", "Currency.name") }

      before do
        Bodhi::Enumeration.cache.clear
      end

      it "should validate a single object" do
        enum = Bodhi::Enumeration.new({name: "Currency", values:[{name: "test"}, {name: "foo"}, {name: "bar"}]})
        puts "\033[33mEnumeration Cache\033[0m: \033[36m#{Bodhi::Enumeration.cache}\033[0m"

        record.foo = "12345"
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must be a Currency.name")

        record.errors.clear
        record.foo = "test"
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to be_empty
      end

      it "should validate arrays of objects" do
        enum = Bodhi::Enumeration.new({name: "Currency", values:[{name: "test"}, {name: "foo"}, {name: "bar"}]})
        puts "\033[33mEnumeration Cache\033[0m: \033[36m#{Bodhi::Enumeration.cache}\033[0m"

        record.foo = ["12345", "test"]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must contain only Currency.name objects")

        record.errors.clear
        record.foo = ["test", "foo", "bar"]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to be_empty
      end
    end

    context "when :attribute is Embedded" do
      let(:validator){ Bodhi::TypeValidator.new("MyClass") }
      let(:type){ Bodhi::Type.new({ name: "MyClass", package: "test", properties: { test:{ type: "String" } } }) }

      after do
        Object.send(:remove_const, :MyClass)
      end

      it "should validate the embedded objects attributes" do
        Bodhi::Type.create_class_with(type)

        record.foo = MyClass.new
        record.foo.test = 12345
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo.test must be a String")

        record.errors.clear
        record.foo = [MyClass.new, MyClass.new]
        record.foo[0].test = 12345
        record.foo[1].test = 12345
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo[0].test must be a String")
        expect(record.errors.full_messages).to include("foo[1].test must be a String")
      end

      it "should validate a single object" do
        Object.const_set("MyClass", Class.new)

        record.foo = Class.new
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must be a MyClass")

        record.errors.clear
        record.foo = MyClass.new
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to be_empty
      end

      it "should validate arrays of objects" do
        Object.const_set("MyClass", Class.new)

        record.foo = [MyClass.new, Class.new]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must contain only MyClasss")

        record.errors.clear
        record.foo = [MyClass.new, MyClass.new]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to be_empty
      end
    end
  end
end