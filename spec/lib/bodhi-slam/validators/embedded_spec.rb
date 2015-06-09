require 'spec_helper'

describe Bodhi::EmbeddedValidator do
  describe "#validate(record, attribute, value)" do
    let(:embedded_klass){ Object.const_set(:TestEmbedded, Class.new) }
    let(:validator){ Bodhi::EmbeddedValidator.new(:TestEmbedded) }
    let(:klass) do
      Class.new do
        include Bodhi::Validations
        attr_accessor :foo
      end
    end
    let(:record){ klass.new }
    
    context "when :value is a single object" do
      it "should add error if :value is not a type of :embedded_klass" do
        Object.const_set("TestEmbedded", Class.new) #no clue why i need to do this again here..  :(
      
        record.foo = "test"
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must be a #{embedded_klass}")
      end
    
      it "should not add error if :value is a type of :embedded_klass" do
        record.foo = embedded_klass.new
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must be a #{embedded_klass}")
      end
      
      it "should not add error if :value is nil" do
        record.foo = nil
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must be a #{embedded_klass}")
        expect(record.errors.full_messages).to_not include("foo must contain only #{embedded_klass} objects")
      end
    end
    
    context "when :value is an array" do
      it "should add error if any :value is not a :embedded_klass object" do
        record.foo = [embedded_klass.new, embedded_klass.new, 12345]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to include("foo must contain only #{embedded_klass} objects")
        expect(record.errors.full_messages).to_not include("foo must be a #{embedded_klass}")
      end
      
      it "should not add any errors if :value is empty" do
        record.foo = []
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must contain only #{embedded_klass} objects")
        expect(record.errors.full_messages).to_not include("foo must be a #{embedded_klass}")
      end
      
      it "should not add any errors if all :values are :embedded_klass objects" do
        record.foo = [embedded_klass.new, embedded_klass.new, embedded_klass.new]
        validator.validate(record, :foo, record.foo)
        expect(record.errors.full_messages).to_not include("foo must contain only #{embedded_klass} objects")
        expect(record.errors.full_messages).to_not include("foo must be a #{embedded_klass}")
      end
    end
  end
end