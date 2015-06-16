require 'spec_helper'

describe Bodhi::Type do
  let(:type){ Bodhi::Type.new }
  
  it "includes Bodhi::Validations" do
    expect(type.class.ancestors).to include Bodhi::Validations
  end
  
  describe "#name" do
    let(:type){ Bodhi::Type.new({ name: "test" }) }
    
    it "is a string" do
      expect(type.name).to be_a String
    end
    
    it "must be present" do
      type.name = nil
      expect(type.valid?).to be false
      expect(type.errors.include?(:name)).to be true
      expect(type.errors[:name]).to include "is required"
    end
    
    it "can not be blank" do
      type.name = ""
      expect(type.valid?).to be false
      expect(type.errors.include?(:name)).to be true
      expect(type.errors[:name]).to include "can not be blank"
    end
  end
  
  describe "#namespace" do
    let(:type){ Bodhi::Type.new({ namespace: "test" }) }
    
    it "is a string" do
      expect(type.namespace).to be_a String
    end
    
    it "must be present" do
      type.namespace = nil
      expect(type.valid?).to be false
      expect(type.errors.include?(:namespace)).to be true
      expect(type.errors[:namespace]).to include "is required"
    end
  end
  
  describe "#package" do
    let(:type){ Bodhi::Type.new({ package: "test" }) }
    
    it "is a string" do
      expect(type.package).to be_a String
    end
  end
  
  describe "#embedded" do
    let(:type){ Bodhi::Type.new({ embedded: true }) }
    
    it "is a boolean" do
      expect(type.embedded).to be true
    end
  end
  
  describe "#properties" do
    let(:type){ Bodhi::Type.new({ properties: { foo: { type: "String", required: true } } }) }
    
    it "is a hash" do
      expect(type.properties).to be_a Hash
    end
    
    it "must be present" do
      type.properties = nil
      expect(type.valid?).to be false
      expect(type.errors.include?(:properties)).to be true
      expect(type.errors[:properties]).to include "is required"
    end
  end
  
  describe "#validations" do
    let(:type){ Bodhi::Type.new({ properties: { foo: { type: "String", required: true }, bar: { type: "Integer", required: true, multi: true } } }) }
    
    it "is a hash" do
      expect(type.validations).to be_a Hash
    end
    
    it "contains all validations for the type keyed by attribute name" do
      expect(type.validations[:foo]).to match_array [Bodhi::TypeValidator, Bodhi::RequiredValidator]
      expect(type.validations[:bar]).to match_array [Bodhi::TypeValidator, Bodhi::RequiredValidator, Bodhi::MultiValidator]
    end
  end
  
  describe ".find_all(context)" do
    let(:context){ Bodhi::Context.new({ server: nil, namespace: nil, cookie: nil }) }
    
    context "with invalid context" do
      it "returns Bodhi::Errors" do
        expect{ Bodhi::Type.find_all(context) }.to raise_error(Bodhi::Errors)
      end
    end
    
    context "with valid context" do
      let(:context){ Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: ENV['QA_TEST_COOKIE'] }) }
      
      it "returns an array of Bodhi::Type objects" do
        types = Bodhi::Type.find_all(context)
        expect(types).to be_a Array
        types.each{ |type| expect(type).to be_a Bodhi::Type }
        #puts types.to_s
      end
    end
  end
  
  describe ".create_class_with(type)" do
    let(:type) do
      Bodhi::Type.new({
        name: "TestCreateType",
        properties: { foo: { type: "String", required: true }, bar: { type: "Integer", required: true, multi: true } } 
      })
    end
    
    context "with invalid argument" do
      it "returns an ArgumentError if :type is not a Bodhi::Type" do
        type = "test"
        expect{ Bodhi::Type.create_class_with(type) }.to raise_error(ArgumentError, "Expected String to be a Bodhi::Type")
      end
    end
    
    context "with valid argument" do
      it "returns the class defined by the type argument" do
        klass = Bodhi::Type.create_class_with(type)
        expect(klass.name).to eq "TestCreateType"
        expect(klass.validators[:foo]).to match_array([ Bodhi::TypeValidator, Bodhi::RequiredValidator ])
        expect(klass.validators[:bar]).to match_array([ Bodhi::TypeValidator, Bodhi::RequiredValidator, Bodhi::MultiValidator ])
        
        obj = klass.new
        obj.foo = "test"
        obj.bar = [10, 20, 30]
        obj.valid?
        expect(obj.errors.messages).to eq Hash.new
      end
    end
  end

  describe ".create_factory_with(type, enums=[])" do

    after do
      FactoryGirl.factories.clear
      Object.send(:remove_const, :TestType) if Object.const_defined?(:TestType)
    end

    it "should raise ArgumentError if :type is not a Bodhi::Type" do
      expect{ Bodhi::Type.create_factory_with(1234) }.to raise_error(ArgumentError, "Expected Fixnum to be a Bodhi::Type")
    end

    context "with GeoJSON properties" do
      context "and multi=true" do
        let(:type){ Bodhi::Type.new({ name: "TestType", package: "test", properties: { foo:{ type: "GeoJSON", multi: true} } }) }

        it "should return 0..5 random GeoJSON objects in an Array" do
          Bodhi::Type.create_class_with(type)
          Bodhi::Type.create_factory_with(type)

          obj = FactoryGirl.build(:TestType)
          expect(obj.foo).to be_a Array
          expect(obj.foo.size).to be_between(0,5)
          puts "Generated object was: #{obj.attributes}"
        end
      end

      context "and multi=false" do
        let(:type){ Bodhi::Type.new({ name: "TestType", package: "test", properties: { foo:{ type: "GeoJSON"} } }) }

        it "should return a random GeoJSON object" do
          Bodhi::Type.create_class_with(type)
          Bodhi::Type.create_factory_with(type)

          obj = FactoryGirl.build(:TestType)
          expect(obj.foo).to be_a Hash
          expect(obj.foo).to have_key :type
          expect(obj.foo).to have_key :coordinates
          expect(obj.foo[:coordinates]).to be_a Array
          puts "Generated object was: #{obj.attributes}"
        end
      end
    end

    context "with Boolean properties" do
      context "and multi=true" do
        let(:type){ Bodhi::Type.new({ name: "TestType", package: "test", properties: { foo:{ type: "Boolean", multi: true} } }) }

        it "should return 0..5 random Booleans in an Array" do
          Bodhi::Type.create_class_with(type)
          Bodhi::Type.create_factory_with(type)

          obj = FactoryGirl.build(:TestType)
          expect(obj.foo).to be_a Array
          expect(obj.foo.size).to be_between(0,5)
          puts "Generated object was: #{obj.attributes}"
        end
      end

      context "and multi=false" do
        let(:type){ Bodhi::Type.new({ name: "TestType", package: "test", properties: { foo:{ type: "Boolean"} } }) }

        it "should return a random Boolean" do
          Bodhi::Type.create_class_with(type)
          Bodhi::Type.create_factory_with(type)

          obj = FactoryGirl.build(:TestType)
          expect(obj.foo).to_not be_nil
          puts "Generated object was: #{obj.attributes}"
        end
      end
    end

    context "with Enumerated properties" do
      let(:enum){ Bodhi::Enumeration.new({ name: "TestEnum", values: [{name: "foo"}, {name: "bar"}, {name: "test"}, {name: "awesome"}, {name: "!@$*&^%"}] }) }
      let(:enum2){ Bodhi::Enumeration.new({ name: "TestEnum2", values: [10, 20, 40, 50, 100, 300, 700, 2] }) }

      after do
        Object.send(:remove_const, :TestType2)
      end

      context "and multi=true" do
        let(:type){ Bodhi::Type.new({ name: "TestType", package: "test", properties: { foo:{ type: "Enumerated", ref: "TestEnum.name", multi: true} } }) }
        let(:type2){ Bodhi::Type.new({ name: "TestType2", package: "test", properties: { foo:{ type: "Enumerated", ref: "TestEnum2", multi: true} } }) }

        it "should return 0..5 random Embedded values in an Array" do
          Bodhi::Type.create_class_with(type)
          Bodhi::Type.create_class_with(type2)
          Bodhi::Type.create_factory_with(type, [enum, enum2])
          Bodhi::Type.create_factory_with(type2, [enum, enum2])

          obj = FactoryGirl.build(:TestType)
          expect(obj.foo).to be_a Array
          expect(obj.foo.size).to be_between(0,5)
          values = enum.values.collect{|value| value[:name] }
          obj.foo.each do |value|
            expect(values).to include value
          end
          puts "Generated object was: #{obj.attributes}"

          obj = FactoryGirl.build(:TestType2)
          expect(obj.foo).to be_a Array
          expect(obj.foo.size).to be_between(0,5)
          obj.foo.each do |value|
            expect(enum2.values).to include value
          end
          puts "Generated object was: #{obj.attributes}"
        end
      end

      context "and multi=false" do
        let(:type){ Bodhi::Type.new({ name: "TestType", package: "test", properties: { foo:{ type: "Enumerated", ref: "TestEnum.name"} } }) }
        let(:type2){ Bodhi::Type.new({ name: "TestType2", package: "test", properties: { foo:{ type: "Enumerated", ref: "TestEnum2"} } }) }

        it "should return a random Enumerated value" do
          Bodhi::Type.create_class_with(type)
          Bodhi::Type.create_class_with(type2)
          Bodhi::Type.create_factory_with(type, [enum, enum2])
          Bodhi::Type.create_factory_with(type2, [enum, enum2])

          obj = FactoryGirl.build(:TestType)
          values = enum.values.collect{|value| value[:name] }
          expect(values).to include obj.foo
          puts "Generated object was: #{obj.attributes}"

          obj = FactoryGirl.build(:TestType2)
          expect(enum2.values).to include obj.foo
          puts "Generated object was: #{obj.attributes}"
        end
      end
    end

    context "with Object properties" do
      context "and multi=true" do
        let(:type){ Bodhi::Type.new({ name: "TestType", package: "test", properties: { foo:{ type: "Object", multi: true} } }) }

        it "should return 0..5 random JSON Objects in an Array" do
          Bodhi::Type.create_class_with(type)
          Bodhi::Type.create_factory_with(type)

          obj = FactoryGirl.build(:TestType)
          expect(obj.foo).to be_a Array
          expect(obj.foo.size).to be_between(0,5)
          expect(obj.foo[0]).to be_a Hash if obj.foo.size > 0
          puts "Generated object was: #{obj.attributes}"
        end
      end

      context "and multi=false" do
        let(:type){ Bodhi::Type.new({ name: "TestType", package: "test", properties: { foo:{ type: "Object"} } }) }

        it "should return a random String" do
          Bodhi::Type.create_class_with(type)
          Bodhi::Type.create_factory_with(type)

          obj = FactoryGirl.build(:TestType)
          expect(obj.foo).to be_a Hash
          puts "Generated object was: #{obj.attributes}"
        end
      end
    end

    context "with String properties" do
      context "and multi=true" do
        let(:type){ Bodhi::Type.new({ name: "TestType", package: "test", properties: { foo:{ type: "String", multi: true} } }) }

        it "should return 0..5 random Strings in an Array" do
          Bodhi::Type.create_class_with(type)
          Bodhi::Type.create_factory_with(type)

          obj = FactoryGirl.build(:TestType)
          expect(obj.foo).to be_a Array
          expect(obj.foo.size).to be_between(0,5)
          expect(obj.foo[0]).to be_a String if obj.foo.size > 0
          puts "Generated object was: #{obj.attributes}"
        end
      end

      context "and multi=false" do
        let(:type){ Bodhi::Type.new({ name: "TestType", package: "test", properties: { foo:{ type: "String"} } }) }

        it "should return a random String" do
          Bodhi::Type.create_class_with(type)
          Bodhi::Type.create_factory_with(type)

          obj = FactoryGirl.build(:TestType)
          expect(obj.foo).to be_a String
          puts "Generated object was: #{obj.attributes}"
        end
      end
    end

    context "with DateTime properties" do
      context "and multi=true" do
        let(:type){ Bodhi::Type.new({ name: "TestType", package: "test", properties: { foo:{ type: "DateTime", multi: true} } }) }

        it "should return 0..5 random DateTimes as Strings in an Array" do
          Bodhi::Type.create_class_with(type)
          Bodhi::Type.create_factory_with(type)

          obj = FactoryGirl.build(:TestType)
          expect(obj.foo).to be_a Array
          expect(obj.foo.size).to be_between(0,5)
          expect(Time.parse(obj.foo[0])).to be_a Time if obj.foo.size > 0
          puts "Generated object was: #{obj.attributes}"
        end
      end

      context "and multi=false" do
        let(:type){ Bodhi::Type.new({ name: "TestType", package: "test", properties: { foo:{ type: "DateTime"} } }) }

        it "should return a random DateTime as a String" do
          Bodhi::Type.create_class_with(type)
          Bodhi::Type.create_factory_with(type)

          obj = FactoryGirl.build(:TestType)
          expect(Time.parse(obj.foo)).to be_a Time
          puts "Generated object was: #{obj.attributes}"
        end
      end
    end

    context "with Integer properties" do
      context "and multi=true" do
        let(:type){ Bodhi::Type.new({ name: "TestType", package: "test", properties: { foo:{ type: "Integer", multi: true} } }) }

        it "should return 0..5 random Integers in an Array" do
          Bodhi::Type.create_class_with(type)
          Bodhi::Type.create_factory_with(type)

          obj = FactoryGirl.build(:TestType)
          expect(obj.foo).to be_a Array
          expect(obj.foo.size).to be_between(0,5)
          expect(obj.foo[0]).to be_a Integer if obj.foo.size > 0
          puts "Generated object was: #{obj.attributes}"
        end
      end

      context "and multi=false" do
        let(:type){ Bodhi::Type.new({ name: "TestType", package: "test", properties: { foo:{ type: "Integer"} } }) }

        it "should return a random Integer" do
          Bodhi::Type.create_class_with(type)
          Bodhi::Type.create_factory_with(type)

          obj = FactoryGirl.build(:TestType)
          expect(obj.foo).to be_a Integer
          puts "Generated object was: #{obj.attributes}"
        end
      end
    end

    context "with Real (Float) properties" do
      context "and multi=true" do
        let(:type){ Bodhi::Type.new({ name: "TestType", package: "test", properties: { foo:{ type: "Real", multi: true} } }) }

        it "should return 0..5 random Reals (Floats) in an Array" do
          Bodhi::Type.create_class_with(type)
          Bodhi::Type.create_factory_with(type)

          obj = FactoryGirl.build(:TestType)
          expect(obj.foo).to be_a Array
          expect(obj.foo.size).to be_between(0,5)
          expect(obj.foo[0]).to be_a Float if obj.foo.size > 0
          puts "Generated object was: #{obj.attributes}"
        end
      end

      context "and multi=false" do
        let(:type){ Bodhi::Type.new({ name: "TestType", package: "test", properties: { foo:{ type: "Real"} } }) }

        it "should return a random Real (Float)" do
          Bodhi::Type.create_class_with(type)
          Bodhi::Type.create_factory_with(type)

          obj = FactoryGirl.build(:TestType)
          expect(obj.foo).to be_a Float
          puts "Generated object was: #{obj.attributes}"
        end
      end
    end

    context "with Embedded properties" do
      let(:test_embedded){ Bodhi::Type.new({ name: "TestEmbedded", package: "test", properties: { bar:{ type: "Integer", multi: true }, baz:{ type: "String" } } }) }

      before do
        Bodhi::Type.create_class_with(type)
        Bodhi::Type.create_class_with(test_embedded)
        Bodhi::Type.create_factory_with(test_embedded)
      end

      after do
        Object.send(:remove_const, :TestEmbedded)
      end

      context "and multi=true" do
        let(:type){ Bodhi::Type.new({ name: "TestType", package: "test", properties: { foo:{ type: "TestEmbedded", multi: true} } }) }

        it "should return 0..5 random Embedded objects in an Array" do
          Bodhi::Type.create_factory_with(type)
          obj = FactoryGirl.build(:TestType)

          expect(obj.foo).to be_a Array
          expect(obj.foo.size).to be_between(0,5)
          obj.foo.each{ |value| expect(value).to be_instance_of(TestEmbedded) } if obj.foo.size > 0

          puts "Generated object was: #{obj.attributes}"
        end
      end

      context "and multi=false" do
        let(:type){ Bodhi::Type.new({ name: "TestType", package: "test", properties: { foo:{ type: "TestEmbedded"} } }) }

        it "should return a random Embedded object" do
          Bodhi::Type.create_factory_with(type)
          obj = FactoryGirl.build(:TestType)

          expect(obj.foo).to be_a TestEmbedded

          puts "Generated object was: #{obj.attributes}"
        end
      end
    end

  end
end