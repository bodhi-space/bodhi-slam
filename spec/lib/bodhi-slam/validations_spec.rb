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
      
      expect(obj.errors.any?).to be false
    end
    
    context "with errors" do
      it "should add all errors to the object" do
        obj.validate!
        expect(obj.errors.any?).to be true
        expect(obj.errors.full_messages).to include("foo is required")
      end
    end
    
    context "with no errors" do
      it "should not add any errors to the object" do
        obj.foo = "foo"
        obj.validate!
        expect(obj.errors.any?).to be false
        expect(obj.errors.full_messages).to_not include("foo is required")
      end
    end
  end
  
  describe "#valid?" do
    let(:klass) do
      Class.new do
        include Bodhi::Validations
        attr_accessor :foo
        validates :foo, required: true
      end
    end
    let(:obj){ klass.new }
    
    context "with errors present" do
      it "should return false" do
        expect(obj.valid?).to be false
      end
    end
    
    context "with no errors present" do
      it "should return true" do
        obj.foo = 12345
        expect(obj.valid?).to be true
      end
    end
  end
  
  describe "#invalid?" do
    let(:klass) do
      Class.new do
        include Bodhi::Validations
        attr_accessor :foo
        validates :foo, required: true
      end
    end
    let(:obj){ klass.new }
    
    context "with errors present" do
      it "should return true" do
        expect(obj.invalid?).to be true
      end
    end
    
    context "with no errors present" do
      it "should return false" do
        obj.foo = 12345
        expect(obj.invalid?).to be false
      end
    end
  end
  
  describe ".validates(attribute, options)" do
    let(:klass) do
      Class.new do
        include Bodhi::Validations
        attr_accessor :foo, :bar, :baz
      end
    end
    
    context "with invalid parameters" do
      it "should raise ArgumentError when the attribute is not a symbol" do
        expect{ klass.validates(12345, {}) }.to raise_error(ArgumentError, "Invalid :attribute argument. Expected Fixnum to be a Symbol")
      end
      
      it "should raise ArgumentError when options are not a hash" do
        expect{ klass.validates(:foo, "test") }.to raise_error(ArgumentError, "Invalid :options argument. Expected String to be a Hash")
      end
      
      it "should raise ArgumentError if an option does not exist" do
        expect{ klass.validates(:foo, { required: true }) }.to_not raise_error
        expect{ klass.validates(:foo, { bar: true }) }.to raise_error(NameError)
      end
    end
    
    it "should add the validation to the validations hash for the given attribute" do
      klass.validates(:foo, type: "String", required: true)
      klass.validates(:bar, type: "MyClass", required: true, multi: true)
      klass.validates(:baz, type: "Enumerated", ref: "MyEnum.name", required: true)
      
      expect(klass.validators.keys).to match_array([ :foo, :bar, :baz ])
      expect(klass.validators[:foo]).to match_array([Bodhi::RequiredValidator, Bodhi::TypeValidator])
      expect(klass.validators[:bar]).to match_array([Bodhi::RequiredValidator, Bodhi::TypeValidator, Bodhi::MultiValidator])
      expect(klass.validators[:baz]).to match_array([Bodhi::RequiredValidator, Bodhi::TypeValidator])
    end
  end
  
  describe ".validators" do
    let(:klass) do
      Class.new do
        include Bodhi::Validations
        attr_accessor :foo, :bar, :baz
        validates :foo, required: true, multi: true
        validates :bar, required: true
      end
    end
    
    it "returns a Hash" do
      expect(klass.validators).to be_a Hash
    end
    
    it "returns class attribute names as keys in the Hash" do
      expect(klass.validators).to have_key :foo
      expect(klass.validators).to have_key :bar
      expect(klass.validators).to_not have_key :baz
    end
    
    it "returns an array for Bodhi::Validators for each class attribute" do
      expect(klass.validators[:foo]).to match_array([Bodhi::RequiredValidator, Bodhi::MultiValidator])
      expect(klass.validators[:bar]).to match_array(Bodhi::RequiredValidator)
    end
  end
end