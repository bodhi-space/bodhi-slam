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
      expect(type.validations[:foo]).to match_array [Bodhi::StringValidation, Bodhi::RequiredValidation]
      expect(type.validations[:bar]).to match_array [Bodhi::IntegerValidation, Bodhi::RequiredValidation, Bodhi::MultiValidation]
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
        puts types.to_s
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
        expect(klass.validations[:foo]).to match_array([ Bodhi::StringValidation, Bodhi::RequiredValidation ])
        expect(klass.validations[:bar]).to match_array([ Bodhi::IntegerValidation, Bodhi::RequiredValidation, Bodhi::MultiValidation ])
        
        obj = klass.new
        obj.foo = "test"
        obj.bar = [10, 20, 30]
        obj.valid?
        expect(obj.errors.messages).to eq Hash.new
      end
    end
  end
end