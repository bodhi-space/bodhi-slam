require 'spec_helper'

describe Bodhi::Factory do
  let(:klass){ Object.const_set("Test", Class.new{ include Bodhi::Resource; attr_accessor :foo }) }
  let(:factory){ Bodhi::Factory.new(klass) }

  after do
    Object.send(:remove_const, :Test)
  end

  describe "#klass" do
    it "returns the class that the factory will generate" do
      expect(factory.klass).to eq Test
    end
  end

  describe "#generators" do
    it "should be a Hash" do
      expect(factory.generators).to be_a Hash
    end
  end

  describe "#build(*args)" do
    it "should return an instance of the type #klass" do
      expect(factory.build).to be_a Test
    end

    it "should randomly generate values for each of the types properties" do
      factory.add_generator("foo", type: "Integer", min: -10, max: 10)

      obj = factory.build
      expect(obj.foo).to be_a Integer
      expect(obj.foo).to be_between(-10, 10)
    end

    it "should override attributes for the object if an attribute hash is given" do
      factory.add_generator("foo", type: "Integer", min: -10, max: 10)

      obj = factory.build(foo: 125)
      expect(obj.foo).to be_a Integer
      expect(obj.foo).to eq 125
    end
  end

  describe "#build_list(size, *args)" do
    it "should return an array of #klass objects" do
      expect(factory.build_list(5)).to be_a Array
      expect(factory.build_list(5).size).to eq 5
      factory.build_list(5).each do |obj|
        expect(obj).to be_a Test
      end
    end

    it "should randomly generate values for each object in the array" do
      factory.add_generator("foo", type: "Integer", min: -10, max: 10)

      factory.build_list(5).each do |obj|
        expect(obj.foo).to be_between(-10, 10)
      end
    end

    it "should override all objects with the specified attributes hash" do
      factory.add_generator("foo", type: "Integer", min: -10, max: 10)

      factory.build_list(5, foo: 125).each do |obj|
        expect(obj.foo).to eq 125
      end
    end
  end

  describe "#create(context, params={})" do
    let(:context){ Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: ENV['QA_TEST_COOKIE'] }) }
    let(:klass){ Object.const_set("Test", Class.new{ include Bodhi::Resource; attr_accessor :Brandon, :Olia, :Alisa }) }
    let(:factory){ Bodhi::Factory.new(klass) }

    before do
      factory.add_generator("Olia", type: "Integer", min: -10, max: 10)
      factory.add_generator("Alisa", type: "String")
      factory.add_generator("Brandon", type: "Boolean")
    end

    after do
      Test.delete_all(context)
    end

    it "should return an instance of the type #klass" do
      expect(factory.create(context)).to be_a Test
    end

    it "should randomly generate values for each of the objects attributes" do
      obj = factory.create(context)
      expect(obj.Olia).to be_a Integer
      expect(obj.Olia).to be_between(-10, 10)
    end

    it "should override attributes for the object if an attribute hash is given" do
      obj = factory.create(context, Olia: 125)
      expect(obj.Olia).to be_a Integer
      expect(obj.Olia).to eq 125
    end

    it "should raise Bodhi::Errors if the context is not valid"
    it "should raise Bodhi::Errors if the resource could not be saved"
  end

  describe "#create_list(size, context, params={})" do
    let(:context){ Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: ENV['QA_TEST_COOKIE'] }) }
    let(:klass){ Object.const_set("Test", Class.new{ include Bodhi::Resource; attr_accessor :Brandon, :Olia, :Alisa }) }
    let(:factory){ Bodhi::Factory.new(klass) }

    before do
      factory.add_generator("Olia", type: "Integer", min: -10, max: 10)
      factory.add_generator("Alisa", type: "String")
      factory.add_generator("Brandon", type: "Boolean")
    end

    after do
      Test.delete_all(context)
    end

    it "should return an array of #klass objects" do
      results = factory.create_list(5, context)
      expect(results).to be_a Array
      expect(results.size).to eq 5
      results.each do |obj|
        expect(obj).to be_a Test
      end
    end

    it "should randomly generate values for each object in the array" do
      factory.create_list(5, context).each do |obj|
        expect(obj.Olia).to be_between(-10, 10)
      end
    end

    it "should override all objects with the specified attributes hash" do
      factory.create_list(5, context, Olia: 125).each do |obj|
        expect(obj.Olia).to eq 125
      end
    end

    it "should raise Bodhi::Errors if the context is not valid"
    it "should raise Bodhi::Errors if any resource could not be saved"
  end


  describe "#add_generator(name, validations)" do
    it "should raise ArgumentError if :name does not exist for the class"

    it "should add the given validations under the :name key" do
      factory.add_generator("foo", type: "Integer")

      expect(factory.generators).to have_key :foo
      expect(factory.generators[:foo]).to be_a Proc
      expect(factory.generators[:foo].call).to be_a Integer
    end

    context "with GeoJSON" do
      context "and multi=true" do
        it "returns 0..5 random GeoJSON objects in an Array" do
          factory.add_generator("foo", type: "GeoJSON", multi: true)
          obj = factory.build

          expect(obj.foo).to be_a Array
          expect(obj.foo.size).to be_between(0,5)
          puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"
        end
      end

      context "and multi=false" do
        it "returns a random GeoJSON object" do
          factory.add_generator("foo", type: "GeoJSON")

          obj = factory.build
          expect(obj.foo).to be_a Hash
          expect(obj.foo).to have_key :type
          expect(obj.foo).to have_key :coordinates
          expect(obj.foo[:coordinates]).to be_a Array
          puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"
        end
      end
    end

    context "with Boolean" do
      context "and multi=true" do
        it "returns 0..5 random Booleans in an Array" do
          factory.add_generator("foo", type: "Boolean", multi: true)

          obj = factory.build
          expect(obj.foo).to be_a Array
          expect(obj.foo.size).to be_between(0,5)
          puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"
        end
      end

      context "and multi=false" do
        it "returns a random Boolean" do
          factory.add_generator("foo", type: "Boolean")

          obj = factory.build
          expect(obj.foo).to_not be_nil
          puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"
        end
      end
    end

    context "with Enumerated" do
      before do
        Bodhi::Enumeration.new({ name: "TestEnum", values: [{name: "foo"}, {name: "bar"}, {name: "test"}, {name: "awesome"}, {name: "!@$*&^%"}] })
        Bodhi::Enumeration.new({ name: "TestEnum2", values: [10, 20, 40, 50, 100, 300, 700, 2] })
      end

      after do
        Bodhi::Enumeration.cache.clear
      end

      context "and multi=true" do
        it "returns 0..5 random Embedded values in an Array" do
          factory.add_generator("foo", type: "Enumerated", ref: "TestEnum.name", multi: true)

          obj = factory.build
          expect(obj.foo).to be_a Array
          expect(obj.foo.size).to be_between(0,5)
          values = Bodhi::Enumeration.cache[:TestEnum].values.collect{|value| value[:name] }
          obj.foo.each do |value|
            expect(values).to include value
          end
          puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"

          factory.add_generator("foo", type: "Enumerated", ref: "TestEnum2", multi: true)
          obj = factory.build
          expect(obj.foo).to be_a Array
          expect(obj.foo.size).to be_between(0,5)
          obj.foo.each do |value|
            expect(Bodhi::Enumeration.cache[:TestEnum2].values).to include value
          end
          puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"
        end
      end

      context "and multi=false" do
        it "returns a random Enumerated value" do
          factory.add_generator("foo", type: "Enumerated", ref: "TestEnum.name")

          obj = factory.build
          values = Bodhi::Enumeration.cache[:TestEnum].values.collect{|value| value[:name] }
          expect(values).to include obj.foo
          puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"

          factory.add_generator("foo", type: "Enumerated", ref: "TestEnum2")
          obj = factory.build
          expect(Bodhi::Enumeration.cache[:TestEnum2].values).to include obj.foo
          puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"
        end
      end
    end

    context "with Object" do
      context "and multi=true" do
        it "returns 0..5 random JSON Objects in an Array" do
          factory.add_generator("foo", type: "Object", multi: true)

          obj = factory.build
          expect(obj.foo).to be_a Array
          expect(obj.foo.size).to be_between(0,5)
          expect(obj.foo[0]).to be_a Hash if obj.foo.size > 0
          puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"
        end
      end

      context "and multi=false" do
        it "returns a random String" do
          factory.add_generator("foo", type: "Object")

          obj = factory.build
          expect(obj.foo).to be_a Hash
          puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"
        end
      end
    end

    context "with String" do
      context "and multi=true" do
        it "returns 0..5 random Strings in an Array" do
          factory.add_generator("foo", type: "String", multi: true)

          obj = factory.build
          expect(obj.foo).to be_a Array
          expect(obj.foo.size).to be_between(0,5)
          expect(obj.foo[0]).to be_a String if obj.foo.size > 0
          puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"
        end
      end

      context "and multi=false" do
        it "returns a random String" do
          factory.add_generator("foo", type: "String")

          obj = factory.build
          expect(obj.foo).to be_a String
          puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"
        end
      end
    end

    context "with DateTime" do
      context "and multi=true" do
        it "returns 0..5 random DateTimes as Strings in an Array" do
          factory.add_generator("foo", type: "DateTime", multi: true)

          obj = factory.build
          expect(obj.foo).to be_a Array
          expect(obj.foo.size).to be_between(0,5)
          expect(Time.parse(obj.foo[0])).to be_a Time if obj.foo.size > 0
          puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"
        end
      end

      context "and multi=false" do
        it "returns a random DateTime as a String" do
          factory.add_generator("foo", type: "DateTime")

          obj = factory.build
          expect(Time.parse(obj.foo)).to be_a Time
          puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"
        end
      end
    end

    context "with Integer" do
      context "and multi=true" do
        it "returns 0..5 random Integers in an Array" do
          factory.add_generator("foo", type: "Integer", multi: true)

          obj = factory.build
          expect(obj.foo).to be_a Array
          expect(obj.foo.size).to be_between(0,5)
          expect(obj.foo[0]).to be_a Integer if obj.foo.size > 0
          puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"
        end
      end

      context "and multi=false" do
        it "returns a random Integer" do
          factory.add_generator("foo", type: "Integer")

          obj = factory.build
          expect(obj.foo).to be_a Integer
          puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"
        end
      end
    end

    context "with Real (Float)" do
      context "and multi=true" do
        it "returns 0..5 random Reals (Floats) in an Array" do
          factory.add_generator("foo", type: "Real", multi: true)

          obj = factory.build
          expect(obj.foo).to be_a Array
          expect(obj.foo.size).to be_between(0,5)
          expect(obj.foo[0]).to be_a Float if obj.foo.size > 0
          puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"
        end
      end

      context "and multi=false" do
        it "returns a random Real (Float)" do
          factory.add_generator("foo", type: "Real")

          obj = factory.build
          expect(obj.foo).to be_a Float
          puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"
        end
      end
    end

    context "with Embedded" do
      before do
        Object.const_set("TestEmbedded", Class.new{ include Bodhi::Resource; attr_accessor :test })
        TestEmbedded.factory.add_generator("test", type: "String")
      end

      after do
        Object.send(:remove_const, :TestEmbedded)
      end

      context "and multi=true" do
        it "returns 0..5 random Embedded objects in an Array" do
          factory.add_generator("foo", type: "TestEmbedded", multi: true)

          obj = factory.build
          expect(obj.foo).to be_a Array
          expect(obj.foo.size).to be_between(0,5)
          obj.foo.each{ |value| expect(value).to be_instance_of(TestEmbedded) } if obj.foo.size > 0
          obj.foo.each{ |value| expect(value.test).to be_a String } if obj.foo.size > 0

          puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"
        end
      end

      context "and multi=false" do
        it "returns a random Embedded object" do
          factory.add_generator("foo", type: "TestEmbedded")

          obj = factory.build
          expect(obj.foo).to be_a TestEmbedded
          expect(obj.foo.test).to be_a String
          puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"
        end
      end
    end
  end


end