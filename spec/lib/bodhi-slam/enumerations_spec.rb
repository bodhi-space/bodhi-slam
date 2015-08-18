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
      end
    end
    
    context "with invalid context" do
      it "should return Bodhi::Errors" do
        bodhi_context = Bodhi::Context.new({ server: nil, namespace: nil, cookie: nil })
        expect{ Bodhi::Enumeration.find_all(bodhi_context) }.to raise_error(Bodhi::ContextErrors)
      end

      it "should return Bodhi::ApiErrors if unauthorized" do
        bodhi_context = Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: nil })
        expect{ Bodhi::Enumeration.find_all(bodhi_context) }.to raise_error(Bodhi::ApiErrors)
      end
    end
  end

  describe ".cache" do    
    it "returns nil if :enum_name is not found" do
      expect(Bodhi::Enumeration.cache[:test]).to be_nil
    end

    it "returns the Bodhi::Enumeration given by name" do
      expect(Bodhi::Enumeration.cache[enum.name.to_sym]).to eq enum
    end
  end
end