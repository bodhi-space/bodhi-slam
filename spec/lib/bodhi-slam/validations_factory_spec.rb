require 'spec_helper'

describe Bodhi::ValidationFactory do
  describe ".build(attribute_properties)" do
    let(:properties_hash){ { type: "String", required: true }  }
    
    it "returns an Array if no errors occured" do
      expect(Bodhi::ValidationFactory.build(properties_hash)).to be_a Array
    end
    
    it "returns ArgumentError if :attribute_properties is not a Hash" do
      expect{ Bodhi::ValidationFactory.build(12345) }.to raise_error(ArgumentError, "Expected Fixnum to be a Hash")
    end
    
    it "should include Bodhi::RequiredValidation if property is :required" do
      expect(Bodhi::ValidationFactory.build(properties_hash)).to include Bodhi::RequiredValidation
    end
    
    it "should include Bodhi::MultiValidation if property is :multi" do
      properties_hash[:multi] = true
      expect(Bodhi::ValidationFactory.build(properties_hash)).to include Bodhi::MultiValidation
    end
    
    it "should include Bodhi::NotBlankValidation if property is :not_blank" do
      properties_hash[:isNotBlank] = true
      expect(Bodhi::ValidationFactory.build(properties_hash)).to include Bodhi::NotBlankValidation
    end
    
    it "should include Bodhi::ObjectValidation if property is :Object" do
      properties_hash[:type] = "Object"
      expect(Bodhi::ValidationFactory.build(properties_hash)).to include Bodhi::ObjectValidation
    end
    
    it "should include Bodhi::BooleanValidation if property is :Boolean" do
      properties_hash[:type] = "Boolean"
      expect(Bodhi::ValidationFactory.build(properties_hash)).to include Bodhi::BooleanValidation
    end
    
    it "should include Bodhi::StringValidation if property is :String" do
      properties_hash[:type] = "String"
      expect(Bodhi::ValidationFactory.build(properties_hash)).to include Bodhi::StringValidation
    end
    
    it "should include Bodhi::IntegerValidation if property is :Integer" do
      properties_hash[:type] = "Integer"
      expect(Bodhi::ValidationFactory.build(properties_hash)).to include Bodhi::IntegerValidation
    end
    
    it "should include Bodhi::DateTimeValidation if property is :DateTime" do
      properties_hash[:type] = "DateTime"
      expect(Bodhi::ValidationFactory.build(properties_hash)).to include Bodhi::DateTimeValidation
    end
    
    it "should include Bodhi::RealValidation if property is :Real" do
      properties_hash[:type] = "Real"
      expect(Bodhi::ValidationFactory.build(properties_hash)).to include Bodhi::RealValidation
    end
    
    it "should include Bodhi::GeoJSONValidation if property is :GeoJSON" do
      properties_hash[:type] = "GeoJSON"
      expect(Bodhi::ValidationFactory.build(properties_hash)).to include Bodhi::GeoJSONValidation
    end
    
    it "should include Bodhi::EnumeratedValidation if property is :Enumerated" do
      properties_hash[:type] = "Enumerated"
      expect(Bodhi::ValidationFactory.build(properties_hash)).to include Bodhi::EnumeratedValidation
    end
    
    it "should include Bodhi::EmbeddedValidation if property is :Store" do
      properties_hash[:type] = "Store"
      expect(Bodhi::ValidationFactory.build(properties_hash)).to include Bodhi::EmbeddedValidation
    end
  end
end