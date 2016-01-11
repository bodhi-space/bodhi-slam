require 'spec_helper'

describe Bodhi::Factory do
  before(:all) do
    @context = Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: ENV['QA_TEST_COOKIE'] })
    @type = Bodhi::Type.new(name: "TestResource", properties: { foo: { type: "String" }, bar: { type: "Boolean" }, baz: { type: "Integer" } })

    @type.bodhi_context = @context
    @type.save!

    Bodhi::Type.create_class_with(@type)
  end

  after(:all) do
    TestResource.delete!(@context)

    @type.delete!
    Object.send(:remove_const, :TestResource)
  end

  before do
    @factory = Bodhi::Factory.new(TestResource)
    @factory.add_generator(:foo, type: "String")
    @factory.add_generator(:bar, type: "Boolean")
    @factory.add_generator(:baz, type: "Integer", min: -10, max: 10)
  end

  describe "#klass" do
    it "returns the class that the factory will generate" do
      expect(@factory.klass).to eq TestResource
    end
  end

  describe "#generators" do
    it "should be a Hash" do
      expect(@factory.generators).to be_a Hash
    end
  end

  describe "#build(*args)" do
    it "should return an instance of the type #klass" do
      expect(@factory.build).to be_a TestResource
    end

    it "should randomly generate values for each of the types properties" do
      @factory.add_generator("foo", type: "String")

      obj = @factory.build
      expect(obj.foo).to be_a String
    end

    it "should override attributes for the object if an attribute hash is given" do
      @factory.add_generator("foo", type: "String")

      obj = @factory.build(foo: "125")
      expect(obj.foo).to be_a String
      expect(obj.foo).to eq "125"
    end
  end

  describe "#build_list(size, *args)" do
    it "should return an array of #klass objects" do
      expect(@factory.build_list(5)).to be_a Array
      expect(@factory.build_list(5).size).to eq 5
      @factory.build_list(5).each do |obj|
        expect(obj).to be_a TestResource
      end
    end

    it "should randomly generate values for each object in the array" do
      @factory.add_generator("foo", type: "String")

      @factory.build_list(5).each do |obj|
        expect(obj.foo).to be_a String
      end
    end

    it "should override all objects with the specified attributes hash" do
      @factory.add_generator("foo", type: "String")

      @factory.build_list(5, foo: "125").each do |obj|
        expect(obj.foo).to eq "125"
      end
    end
  end

  describe "#create(context, params={})" do
    it "should return an instance of the type #klass" do
      expect(@factory.create(bodhi_context: @context)).to be_a TestResource
    end

    it "should randomly generate values for each of the objects attributes" do
      obj = @factory.create(bodhi_context: @context)
      expect(obj.foo).to be_a String
      expect(obj.baz).to be_a Integer
    end

    it "should override attributes for the object if an attribute hash is given" do
      obj = @factory.create(bodhi_context: @context, foo: "test test")
      expect(obj.foo).to eq "test test"
    end

    it "should raise Bodhi::Errors if the context is not valid" do
      bad_context = Bodhi::Context.new({})
      expect{ @factory.create(bodhi_context: bad_context, baz: 125) }.to raise_error(Bodhi::Errors, '["server is required", "namespace is required"]')
    end

    it "should raise Bodhi::ApiErrors if the resource could not be saved" do
      expect{ @factory.create(bodhi_context: @context, bar: "test") }.to raise_error(Bodhi::ApiErrors)
    end
  end

  describe "#create_list(size, context, params={})" do
    it "should return an array of #klass objects" do
      results = @factory.create_list(5, bodhi_context: @context)
      expect(results).to be_a Array
      expect(results.size).to eq 5
      results.each do |obj|
        expect(obj).to be_a TestResource
      end
    end

    it "should randomly generate values for each object in the array" do
      @factory.create_list(5, bodhi_context: @context).each do |obj|
        expect(obj.baz).to be_between(-10, 10)
      end
    end

    it "should override all objects with the specified attributes hash" do
      @factory.create_list(5, bodhi_context: @context, foo: "test").each do |obj|
        expect(obj.foo).to eq "test"
      end
    end

    it "should raise Bodhi::ContextErrors if the context is invalid" do
      bad_context = Bodhi::Context.new({})
      expect{ @factory.create_list(5, bodhi_context: bad_context, baz: 125) }.to raise_error(Bodhi::Errors, '["server is required", "namespace is required"]')
    end
  end


  describe "#add_generator(name, options)" do
    it "defines a new random generator with the given options (Hash)" do
      @factory.add_generator("foo", type: "Integer")

      expect(@factory.generators).to have_key :foo
      expect(@factory.generators[:foo]).to be_a Proc
      expect(@factory.generators[:foo].call).to be_a Integer
    end

    it "defines a new random generator with the given options (Proc)" do
      @factory.add_generator("foo", lambda{ "why not Zoidberg?" })

      expect(@factory.generators).to have_key :foo
      expect(@factory.generators[:foo]).to be_a Proc
      expect(@factory.generators[:foo].call).to eq "why not Zoidberg?"
    end
  end

  describe "#build_default_generator(options) (private method)" do
    context "with GeoJSON" do
      context "and multi=true" do
        it "returns 0..5 random GeoJSON objects in an Array" do
          @factory.add_generator("foo", type: "GeoJSON", multi: true)
          obj = @factory.build

          expect(obj.foo).to be_a Array
          expect(obj.foo.size).to be_between(0,5)
          puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"
        end
      end

      context "and multi=false" do
        it "returns a random GeoJSON object" do
          @factory.add_generator("foo", type: "GeoJSON")

          obj = @factory.build
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
          @factory.add_generator("foo", type: "Boolean", multi: true)

          obj = @factory.build
          expect(obj.foo).to be_a Array
          expect(obj.foo.size).to be_between(0,5)
          puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"
        end
      end

      context "and multi=false" do
        it "returns a random Boolean" do
          @factory.add_generator("foo", type: "Boolean")

          obj = @factory.build
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
          @factory.add_generator("foo", type: "Enumerated", ref: "TestEnum.name", multi: true)

          obj = @factory.build
          expect(obj.foo).to be_a Array
          expect(obj.foo.size).to be_between(0,5)
          values = Bodhi::Enumeration.cache[:TestEnum].values.collect{|value| value[:name] }
          obj.foo.each do |value|
            expect(values).to include value
          end
          puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"

          @factory.add_generator("foo", type: "Enumerated", ref: "TestEnum2", multi: true)
          obj = @factory.build
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
          @factory.add_generator("foo", type: "Enumerated", ref: "TestEnum.name")

          obj = @factory.build
          values = Bodhi::Enumeration.cache[:TestEnum].values.collect{|value| value[:name] }
          expect(values).to include obj.foo
          puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"

          @factory.add_generator("foo", type: "Enumerated", ref: "TestEnum2")
          obj = @factory.build
          expect(Bodhi::Enumeration.cache[:TestEnum2].values).to include obj.foo
          puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"
        end
      end
    end

    context "with Object" do
      context "and multi=true" do
        it "returns 0..5 random JSON Objects in an Array" do
          @factory.add_generator("foo", type: "Object", multi: true)

          obj = @factory.build
          expect(obj.foo).to be_a Array
          expect(obj.foo.size).to be_between(0,5)
          expect(obj.foo[0]).to be_a Hash if obj.foo.size > 0
          puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"
        end
      end

      context "and multi=false" do
        it "returns a random String" do
          @factory.add_generator("foo", type: "Object")

          obj = @factory.build
          expect(obj.foo).to be_a Hash
          puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"
        end
      end
    end

    context "with String" do
      context "and multi=true" do
        it "returns 0..5 random Strings in an Array" do
          @factory.add_generator("foo", type: "String", multi: true)

          obj = @factory.build
          expect(obj.foo).to be_a Array
          expect(obj.foo.size).to be_between(0,5)
          expect(obj.foo[0]).to be_a String if obj.foo.size > 0
          puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"
        end

        context "and length=true" do
          it "returns a string with the defined length" do
            @factory.add_generator("foo", type: "String", length: "[5,10]", multi: true)

            obj = @factory.build
            expect(obj.foo).to be_a Array
            expect(obj.foo.size).to be_between(0,5)
            expect(obj.foo[0]).to be_a String if obj.foo.size > 0
            obj.foo.each{ |item| expect(item.length).to be_between(5,10) }
            puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"
          end
        end

        context "and matches=true" do
          it "returns a string which matches the regexp" do
            @factory.add_generator("foo", type: "String", matches: "[a-z]{5}", multi: true)

            obj = @factory.build
            expect(obj.foo).to be_a Array
            expect(obj.foo.size).to be_between(0,5)
            expect(obj.foo[0]).to be_a String if obj.foo.size > 0
            obj.foo.each{ |item| expect(item).to match(/[a-z]{5}/) }
            puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"
          end
        end

        context "and is_email=true" do
          it "returns a random email address" do
            @factory.add_generator("foo", type: "String", is_email: true, multi: true)

            obj = @factory.build
            expect(obj.foo).to be_a Array
            expect(obj.foo.size).to be_between(0,5)
            expect(obj.foo[0]).to be_a String if obj.foo.size > 0
            obj.foo.each{ |item| expect(item).to match(/\p{Alnum}{5,10}@\p{Alnum}{5,10}\.\p{Alnum}{2,3}/i) }
            puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"
          end
        end

        context "and is_not_blank=true" do
          it "returns random non-blank Strings" do
            @factory.add_generator("foo", type: "String", is_not_blank: true, multi: true)

            obj = @factory.build
            expect(obj.foo).to be_a Array
            expect(obj.foo.size).to be_between(0,5)
            expect(obj.foo[0]).to be_a String if obj.foo.size > 0
            obj.foo.each{ |item| expect(item).to_not match(/^\s+$/) }
            puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"
          end
        end
      end

      context "and multi=false" do
        it "returns a random String" do
          @factory.add_generator("foo", type: "String")

          obj = @factory.build
          expect(obj.foo).to be_a String
          puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"
        end

        context "and length=true" do
          it "returns a string with the defined length" do
            @factory.add_generator("foo", type: "String", length: "[5,10]")

            obj = @factory.build
            expect(obj.foo).to be_a String
            expect(obj.foo.length).to be_between(5,10)
            puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"
          end
        end

        context "and matches=true" do
          it "returns a string which matches the regexp" do
            @factory.add_generator("foo", type: "String", matches: "[a-z]{5}")

            obj = @factory.build
            expect(obj.foo).to be_a String
            expect(obj.foo).to match(/[a-z]{5}/)
            puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"
          end
        end

        context "and is_email=true" do
          it "returns a random email address" do
            @factory.add_generator("foo", type: "String", is_email: true)

            obj = @factory.build
            expect(obj.foo).to be_a String
            expect(obj.foo).to match(/\p{Alnum}{5,10}@\p{Alnum}{5,10}\.\p{Alnum}{2,3}/i)
            puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"
          end
        end

        context "and is_not_blank=true" do
          it "returns random non-blank Strings" do
            @factory.add_generator("foo", type: "String", is_not_blank: true)

            obj = @factory.build
            expect(obj.foo).to be_a String
            expect(obj.foo).to_not match(/^\s+$/)
            puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"
          end
        end
      end
    end

    context "with DateTime" do
      context "and multi=true" do
        it "returns 0..5 random DateTimes in an Array" do
          @factory.add_generator("foo", type: "DateTime", multi: true)

          obj = @factory.build
          expect(obj.foo).to be_a Array
          expect(obj.foo.size).to be_between(0,5)
          if obj.foo.size > 0
            obj.foo.each{ |item| expect(item).to be_a Time }
          end
          puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"
        end
      end

      context "and multi=false" do
        it "returns a random DateTime as a String" do
          @factory.add_generator("foo", type: "DateTime")

          obj = @factory.build
          expect(obj.foo).to be_a Time
          puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"
        end
      end
    end

    context "with Integer" do
      context "and multi=true" do
        it "returns 0..5 random Integers in an Array" do
          @factory.add_generator("foo", type: "Integer", multi: true)

          obj = @factory.build
          expect(obj.foo).to be_a Array
          expect(obj.foo.size).to be_between(0,5)
          expect(obj.foo[0]).to be_a Integer if obj.foo.size > 0
          puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"
        end
      end

      context "and multi=false" do
        it "returns a random Integer" do
          @factory.add_generator("foo", type: "Integer")

          obj = @factory.build
          expect(obj.foo).to be_a Integer
          puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"
        end
      end
    end

    context "with Real (Float)" do
      context "and multi=true" do
        it "returns 0..5 random Reals (Floats) in an Array" do
          @factory.add_generator("foo", type: "Real", multi: true)

          obj = @factory.build
          expect(obj.foo).to be_a Array
          expect(obj.foo.size).to be_between(0,5)
          expect(obj.foo[0]).to be_a Float if obj.foo.size > 0
          puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"
        end
      end

      context "and multi=false" do
        it "returns a random Real (Float)" do
          @factory.add_generator("foo", type: "Real")

          obj = @factory.build
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
          @factory.add_generator("foo", type: "TestEmbedded", multi: true)

          obj = @factory.build
          expect(obj.foo).to be_a Array
          expect(obj.foo.size).to be_between(0,5)
          obj.foo.each{ |value| expect(value).to be_instance_of(TestEmbedded) } if obj.foo.size > 0
          obj.foo.each{ |value| expect(value.test).to be_a String } if obj.foo.size > 0

          puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"
        end
      end

      context "and multi=false" do
        it "returns a random Embedded object" do
          @factory.add_generator("foo", type: "TestEmbedded")

          obj = @factory.build
          expect(obj.foo).to be_a TestEmbedded
          expect(obj.foo.test).to be_a String
          puts "\033[33mGenerated\033[0m: \033[36m#{obj.attributes}\033[0m"
        end
      end
    end
  end
end