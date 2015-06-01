require 'spec_helper'

describe Bodhi::NotBlankValidation do
  let(:validation){ Bodhi::NotBlankValidation.new }
  let(:klass) do
    Class.new do
      include Bodhi::Validations
      attr_accessor :foo
      validates :foo, not_blank: true
    end
  end
  let(:record){ klass.new }
  
  describe "#validate(record, attribute, value)" do
    it "should add error if :value is a blank string" do
      validation.validate(record, :foo, "")
      expect(record.errors.full_messages).to include("foo can not be blank")
    end
    
    it "should not add error if :value is not blank" do
      validation.validate(record, :foo, "https://google.com")
      expect(record.errors.full_messages).to_not include("foo can not be blank")
    end
  end
end