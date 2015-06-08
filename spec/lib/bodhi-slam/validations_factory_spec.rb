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
      expect(Bodhi::ValidationFactory.build(properties_hash)).to include Bodhi::RequiredValidator
    end
    
    it "should include Bodhi::MultiValidation if property is :multi" do
      properties_hash[:multi] = true
      expect(Bodhi::ValidationFactory.build(properties_hash)).to include Bodhi::MultiValidator
    end
    
    it "should include Bodhi::NotBlankValidation if property is :not_blank" do
      properties_hash[:isNotBlank] = true
      expect(Bodhi::ValidationFactory.build(properties_hash)).to include Bodhi::NotBlankValidator
    end
    
    it "should include Bodhi::ObjectValidation if property is :Object" do
      properties_hash[:type] = "Object"
      expect(Bodhi::ValidationFactory.build(properties_hash)).to include Bodhi::ObjectValidator
    end
    
    it "should include Bodhi::BooleanValidation if property is :Boolean" do
      properties_hash[:type] = "Boolean"
      expect(Bodhi::ValidationFactory.build(properties_hash)).to include Bodhi::BooleanValidator
    end
    
    it "should include Bodhi::StringValidation if property is :String" do
      properties_hash[:type] = "String"
      expect(Bodhi::ValidationFactory.build(properties_hash)).to include Bodhi::StringValidator
    end
    
    it "should include Bodhi::IntegerValidation if property is :Integer" do
      properties_hash[:type] = "Integer"
      expect(Bodhi::ValidationFactory.build(properties_hash)).to include Bodhi::IntegerValidator
    end
    
    it "should include Bodhi::DateTimeValidation if property is :DateTime" do
      properties_hash[:type] = "DateTime"
      expect(Bodhi::ValidationFactory.build(properties_hash)).to include Bodhi::DateTimeValidator
    end
    
    it "should include Bodhi::RealValidation if property is :Real" do
      properties_hash[:type] = "Real"
      expect(Bodhi::ValidationFactory.build(properties_hash)).to include Bodhi::RealValidator
    end
    
    it "should include Bodhi::GeoJSONValidation if property is :GeoJSON" do
      properties_hash[:type] = "GeoJSON"
      expect(Bodhi::ValidationFactory.build(properties_hash)).to include Bodhi::GeoJsonValidator
    end
    
    it "should include Bodhi::EnumeratedValidation if property is :Enumerated" do
      properties_hash[:type] = "Enumerated"
      expect(Bodhi::ValidationFactory.build(properties_hash)).to include Bodhi::EnumeratedValidator
    end
    
    it "should include Bodhi::EmbeddedValidation if property is :Store" do
      properties_hash[:type] = "Store"
      expect(Bodhi::ValidationFactory.build(properties_hash)).to include Bodhi::EmbeddedValidator
    end
  end
end