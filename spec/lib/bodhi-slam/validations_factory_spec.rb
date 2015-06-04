require 'spec_helper'

describe Bodhi::ValidationFactory do
  describe ".build(name)" do
    it "returns ArgumentError if :name is not a symbol or string" do
      expect{ Bodhi::ValidationFactory.build(12345) }.to raise_error(ArgumentError, "Expected Fixnum to be a Symbol")
    end
    
    it "returns Bodhi::RequiredValidation if name is :required" do
      expect(Bodhi::ValidationFactory.build(:required)).to be_a Bodhi::RequiredValidation
    end
    
    it "returns Bodhi::MultiValidation if name is :multi" do
      expect(Bodhi::ValidationFactory.build(:multi)).to be_a Bodhi::MultiValidation
    end
    
    it "returns Bodhi::NotBlankValidation if name is :not_blank" do
      expect(Bodhi::ValidationFactory.build(:not_blank)).to be_a Bodhi::NotBlankValidation
    end
    
    
    it "returns Bodhi::ObjectValidation if name is :Object" do
      expect(Bodhi::ValidationFactory.build(:Object)).to be_a Bodhi::ObjectValidation
    end
    
    it "returns Bodhi::BooleanValidation if name is :Boolean" do
      expect(Bodhi::ValidationFactory.build(:Boolean)).to be_a Bodhi::BooleanValidation
    end
    
    it "returns Bodhi::StringValidation if name is :String" do
      expect(Bodhi::ValidationFactory.build(:String)).to be_a Bodhi::StringValidation
    end
    
    it "returns Bodhi::IntegerValidation if name is :Integer" do
      expect(Bodhi::ValidationFactory.build(:Integer)).to be_a Bodhi::IntegerValidation
    end
    
    it "returns Bodhi::DateTimeValidation if name is :DateTime" do
      expect(Bodhi::ValidationFactory.build(:DateTime)).to be_a Bodhi::DateTimeValidation
    end
    
    it "returns Bodhi::RealValidation if name is :Real" do
      expect(Bodhi::ValidationFactory.build(:Real)).to be_a Bodhi::RealValidation
    end
    
    it "returns Bodhi::GeoJSONValidation if name is :GeoJSON" do
      expect(Bodhi::ValidationFactory.build(:GeoJSON)).to be_a Bodhi::GeoJSONValidation
    end
    
    it "returns Bodhi::EnumeratedValidation if name is :Enumerated" do
      expect(Bodhi::ValidationFactory.build(:Enumerated)).to be_a Bodhi::EnumeratedValidation
    end
  end
end