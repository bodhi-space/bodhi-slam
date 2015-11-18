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

  describe "#indexes" do
    let(:type){ Bodhi::Type.new({ properties: { foo: { type: "String", required: true } }, indexes: [{ keys: ["foo"], options: { unique: true } }] }) }

    it "returns an array of Bodhi::TypeIndex objects" do
      expect(type.indexes).to be_a Array
      expect(type.indexes.size).to eq 1

      type.indexes.each{ |index| expect(index).to be_a Bodhi::TypeIndex }
    end
  end

  describe "#save!" do
    let(:context){ Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: ENV['QA_TEST_COOKIE'] }) }

    it "saves the type to the cloud" do
      type = Bodhi::Type.new(
        bodhi_context: context,
        name: "AutoTest_Type1",
        properties: { foo: { type: "String", required: true }, bar: { type: "String", required: true }},
        indexes: [{ keys: ["foo"], options: { unique: true } }, { keys: ["bar", "foo"], options: { unique: true } }]
      )

      expect{type.save!}.to_not raise_error
      expect(type.persisted?).to be true
      type.delete!
    end
  end

  describe ".factory" do
    it "returns a Bodhi::Factory for creating Bodhi::Types" do
      expect(Bodhi::Type.factory).to be_a Bodhi::Factory
    end

    describe "#build" do
      it "returns a valid Bodhi::Type" do
        expect(Bodhi::Type.factory.build).to be_a Bodhi::Type
        expect(Bodhi::Type.factory.build.valid?).to be true
        puts "\033[33mGenerated\033[0m: \033[36m#{Bodhi::Type.factory.build.attributes}\033[0m"
      end
    end

    describe "#create" do
      let(:context){ Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: ENV['QA_TEST_COOKIE'] }) }

      it "saves a type to the cloud and returns Bodhi::Type" do
        type = Bodhi::Type.factory.create(bodhi_context: context, extends: nil, namespace: context.namespace, name: "AutoTest_Type1", properties: { foo: { type: "String", required: true }, bar: { type: "Integer", required: true, multi: true } } )
        expect(type).to be_a Bodhi::Type
        expect(type.name).to eq "AutoTest_Type1"

        puts "\033[33mGenerated\033[0m: \033[36m#{type.to_json}\033[0m"
        type.delete!
      end
    end
  end

  describe ".find(context, type_name)" do
    let(:context){ Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: ENV['QA_TEST_COOKIE'] }) }

    it "returns Bodhi::ContextErrors if context is invalid" do
      bad_context = Bodhi::Context.new({ server: nil, namespace: nil, cookie: nil })
      expect{ Bodhi::Type.find(bad_context, "test") }.to raise_error(Bodhi::ContextErrors)
    end

    it "returns a Bodhi::Type for the given type_name" do
      type = Bodhi::Type.find(context, "Store")
      expect(type).to be_a Bodhi::Type
    end
  end

  describe ".find_all(context)" do
    let(:context){ Bodhi::Context.new({ server: nil, namespace: nil, cookie: nil }) }
    
    context "with invalid context" do
      it "returns Bodhi::Errors" do
        expect{ Bodhi::Type.find_all(context) }.to raise_error(Bodhi::ContextErrors)
      end
    end
    
    context "with valid context" do
      let(:context){ Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: ENV['QA_TEST_COOKIE'] }) }
      
      it "returns an array of Bodhi::Type objects" do
        types = Bodhi::Type.find_all(context)
        expect(types).to be_a Array
        types.each{ |type| expect(type).to be_a Bodhi::Type }
      end
    end
  end
  
  describe ".create_class_with(type)" do
    let(:type) do
      Bodhi::Type.new({
        name: "TestCreateType",
        properties: { foo: { type: "String", required: true }, bar: { type: "Integer", required: true, multi: true }, something: { type: "String", system: true } }
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

      it "does not add factory generators for system properties" do
        klass = Bodhi::Type.create_class_with(type)
        expect(klass.factory.build.attributes).to have_key :foo
        expect(klass.factory.build.attributes).to have_key :bar
        expect(klass.factory.build.attributes).to_not have_key :something

        expect(klass.factory.build.something).to eq nil
      end
    end
  end
end