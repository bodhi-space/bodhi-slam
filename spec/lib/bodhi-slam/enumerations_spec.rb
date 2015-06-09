require 'spec_helper'

describe Bodhi::Enumeration do
  let(:enum){ Bodhi::Enumeration.new({name: "TestEnum", values: ["test", "foo"]}) }
  
  describe "#name" do
    it "should be a String" do
      expect(enum.name).to be_a String
      expect(enum.name).to eq "TestEnum"
    end
  end
  
  describe "#values" do
    it "should be an Array" do
      expect(enum.values).to be_a Array
      expect(enum.values).to match_array(["test", "foo"])
    end
  end
  
  describe ".find_all(context)" do
    context "with valid context" do
      let(:context){ Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: ENV['QA_TEST_COOKIE'] }) }
      
      it "should return an array of Bodhi::Enumerations from the namespace" do
        enums = Bodhi::Enumeration.find_all(context)
        expect(enums).to be_a Array
        enums.each{ |enumeration| expect(enumeration).to be_a Bodhi::Enumeration }
        #puts enums.to_s
      end
    end
    
    context "with invalid context" do
      let(:context){ Bodhi::Context.new({ server: nil, namespace: nil, cookie: nil }) }
      
      it "should return a Bodhi::Errors" do
        expect{ Bodhi::Enumeration.find_all(context) }.to raise_error(Bodhi::Errors)
      end
    end
  end
end