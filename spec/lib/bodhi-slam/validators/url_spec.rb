require 'spec_helper'

describe Bodhi::UrlValidator do
  let(:validation){ Bodhi::UrlValidator.new }
  let(:klass) do
    Class.new do
      include Bodhi::Validations
      attr_accessor :foo
      validates :foo, url: true
    end
  end
  let(:record){ klass.new }
  
  describe "#validate(record, attribute, value)" do
    it "should add error if :value not a valid URL" do
      validation.validate(record, :foo, record.foo)
      expect(record.errors.full_messages).to include("foo must be a valid URL")
    end
    
    it "should not add error if :value is valid URL" do
      validation.validate(record, :foo, "https://google.com")
      expect(record.errors.full_messages).to_not include("foo must be a valid URL")
    end
  end
end