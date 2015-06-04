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
    context "with invalid context" do
      it "returns Bodhi::ContextErrors"
    end
    
    context "with valid context" do
      it "returns an array of Bodhi::Type objects"
    end
  end
  
  describe ".create_class_with(type)" do
    context "with invalid argument" do
      it "returns an ArgumentError"
    end
    
    context "with valid argument" do
      it "returns the class defined by the type argument"
    end
  end
end