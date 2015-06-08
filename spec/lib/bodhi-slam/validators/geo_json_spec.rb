require 'spec_helper'

describe Bodhi::GeoJsonValidator do
  let(:validation){ Bodhi::GeoJsonValidator.new }
  let(:klass) do
    Class.new do
      include Bodhi::Validations
      attr_accessor :foo
    end
  end
  let(:record){ klass.new }
  
  describe "#validate(record, attribute, value)" do
    it "should add error if :value is not a GeoJSON" do
      record.foo = "test"
      validation.validate(record, :foo, record.foo)
      expect(record.errors.full_messages).to include("foo must be a GeoJSON")
    end
    
    it "should not add error if :value is a GeoJSON" do
      record.foo = {}
      validation.validate(record, :foo, record.foo)
      expect(record.errors.full_messages).to_not include("foo must be a GeoJSON")
    end
  end
end