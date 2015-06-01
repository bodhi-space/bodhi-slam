require 'spec_helper'

describe Bodhi::Validations do
  it "can be included in a class" do
    klass = Class.new { include Bodhi::Validations }
    expect(klass.ancestors).to include Bodhi::Validations
  end
  
  describe "#errors" do
    it "returns a Bodhi::Errors object" do
      klass = Class.new { include Bodhi::Validations }
      expect(klass.new.errors).to be_a Bodhi::Errors
    end
  end
  
  describe "#validate!" do
    let(:klass) do
      Class.new do
        include Bodhi::Validations
        attr_accessor :foo
        validates :foo, required: true
      end
    end
    
    let(:obj){ klass.new }
    
    it "clear any existing errors before validating" do
      obj.foo = "foo"
      obj.errors.add(:test, "existing error")
      expect(obj.errors.messages.any?).to be true
      
      obj.validate!
      
      expect(obj.errors.messages.any?).to be false
    end
    
    context "with errors" do
      it "should add all errors to the object" do
        obj.validate!
        expect(obj.errors.messages.any?).to be true
        expect(obj.errors.full_messages).to include("foo is required")
      end
    end
    
    context "with no errors" do
      it "should not add any errors to the object" do
        obj.foo = "foo"
        obj.validate!
        expect(obj.errors.messages.any?).to be false
        expect(obj.errors.full_messages).to_not include("foo is required")
      end
    end
  end
  
  describe ".validates(attribute, options)" do
    let(:klass) do
      Class.new do
        include Bodhi::Validations
        attr_accessor :foo
      end
    end
    
    context "with invalid parameters" do
      it "should raise ArgumentError when the attribute is not a symbol" do
        expect{ klass.validates(12345, {}) }.to raise_error(ArgumentError, "Invalid :attribute argument. Expected Fixnum to be a Symbol")
      end
      
      it "should raise ArgumentError when options are not a hash" do
        expect{ klass.validates(:foo, "test") }.to raise_error(ArgumentError, "Invalid :options argument. Expected String to be a Hash")
      end
      
      it "should raise ArgumentError if an option doesnt exist" do
        expect{ klass.validates(:foo, { required: true }) }.to_not raise_error
        expect{ klass.validates(:foo, { bar: true }) }.to raise_error(ArgumentError, "Unknown key: :bar. Valid keys are: :required, :multi, :url.")
      end
    end
    
    it "should add the validation to the validations hash for the given attribute" do
      klass.validates(:foo, required: true)
      expect(klass.validations).to have_key :foo
      expect(klass.validations[:foo]).to include Bodhi::RequiredValidation
    end
  end
  
  describe ".validations" do
    let(:klass) do
      Class.new do
        include Bodhi::Validations
        attr_accessor :foo, :bar, :baz
        validates :foo, required: true, multi: true
        validates :bar, required: true
      end
    end
    
    it "returns a Hash" do
      expect(klass.validations).to be_a Hash
    end
    
    it "returns class attribute names as keys in the Hash" do
      expect(klass.validations).to have_key :foo
      expect(klass.validations).to have_key :bar
      expect(klass.validations).to_not have_key :baz
    end
    
    it "returns an array for Bodhi::Validators for each class attribute" do
      expect(klass.validations[:foo]).to match_array([Bodhi::RequiredValidation, Bodhi::MultiValidation])
      expect(klass.validations[:bar]).to match_array(Bodhi::RequiredValidation)
    end
  end
end