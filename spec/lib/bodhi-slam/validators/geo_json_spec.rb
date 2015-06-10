require 'spec_helper'

describe Bodhi::GeoJsonValidator do
  let(:validator){ Bodhi::GeoJsonValidator.new }
  let(:klass) do
    Class.new do
      include Bodhi::Validations
      attr_accessor :foo
    end
  end
  let(:record){ klass.new }
  
  describe "#validate(record, attribute, value)" do
    
    context "when :value is a single object" do
      it "should add error if :value is not a GeoJSON" do
        record.foo = "test"
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must be a GeoJSON")
        expect(record.errors.full_messages).to_not include("foo must contain only GeoJSON objects")
      end
    
      it "should not add error if :value is a GeoJSON" do
        record.foo = {}
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must be a GeoJSON")
        expect(record.errors.full_messages).to_not include("foo must contain only GeoJSON objects")
      end
      
      it "should not add error if :value is nil" do
        record.foo = nil
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must be a GeoJSON")
        expect(record.errors.full_messages).to_not include("foo must contain only GeoJSON objects")
      end
    end
    
    context "when :value is an array" do
      it "should add error if any :value is not a GeoJSON" do
        record.foo = [{}, "test", {}]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must contain only GeoJSON objects")
        expect(record.errors.full_messages).to_not include("foo must be a GeoJSON")
      end
      
      it "should not add any errors if :value is empty" do
        record.foo = []
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must contain only GeoJSON objects")
        expect(record.errors.full_messages).to_not include("foo must be a GeoJSON")
      end
      
      it "should not add any errors if all :values are GeoJSON objects" do
        record.foo = [{}, {}, {}]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must contain only GeoJSON objects")
        expect(record.errors.full_messages).to_not include("foo must be a GeoJSON")
      end
    end
  end
  
  describe "#to_options" do
    it "should return the validator as an option Hash" do
      expect(validator.to_options).to include({geo_json: true})
    end
  end
end