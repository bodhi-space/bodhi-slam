require 'spec_helper'

describe Bodhi::Errors do
  let(:error){ Bodhi::Errors.new }
  
  describe "#clear" do
    it "removes all error messages" do
      expect(error.messages.any?).to be false
      error.add(:test, "no worky!")
      expect(error.messages.any?).to be true
      
      error.clear
      
      expect(error.messages.any?).to be false
    end
  end

  describe "#add" do
    it "pushes a new error to the messages hash" do
      error.add(:test, "no worky!")
      error.add(:test, "another error!")

      expect(error.messages).to be_a Hash
      expect(error.messages).to have_key(:test)
      expect(error.messages[:test]).to include "no worky!"
      expect(error.messages[:test]).to include "another error!"
    end
  end
  
  describe "#messages" do
    let(:error){ Bodhi::Errors.new({test: ["foo", "bar"]}) }
    
    it "returns a hash" do
      expect(error.messages).to be_a Hash
    end
    
    it "includes all error messages grouped by attribute name" do
      expect(error.messages).to have_key(:test)
      expect(error.messages[:test]).to match_array(["foo", "bar"])
    end
  end
  
  describe "#full_messages" do
    let(:error){ Bodhi::Errors.new({test: ["no worky!", "another error!"]}) }
    
    it "returns an array" do
      expect(error.full_messages).to be_a Array
    end
    
    it "includes each error with a full description" do
      expect(error.full_messages).to match_array(["test no worky!", "test another error!"])
    end
  end
  
  describe "#each" do
    let(:error){ Bodhi::Errors.new({foo: ["is required", "must be awesome"]}) }
    
    it "should yield for each error in the messages hash" do
      expect { |block| error.each(&block) }.to yield_successive_args([:foo, "is required"], [:foo, "must be awesome"])
    end
  end
  
  describe "#any?" do
    it "returns true if any errors are present" do
      error = Bodhi::Errors.new({test: ["foo", "bar"]})
      expect(error.any?).to be true
    end
    
    it "returns false if no errors are present" do
      error = Bodhi::Errors.new
      expect(error.any?).to be false
    end
  end
  
  describe "#to_json" do
    let(:error){ Bodhi::Errors.new({test: ["no worky!", "another error!"]}) }
    
    it "should return the messages hash in json format" do
      expect(error.to_json).to be_a String
      expect(error.to_json).to eq "{\"test\":[\"no worky!\",\"another error!\"]}"
    end
  end
  
  describe "#include?(attribute)" do
    let(:error){ Bodhi::Errors.new({test: ["no worky!", "another error!"]}) }
    
    it "returns true if errors contains the attribute" do
      expect(error.include?(:test)).to be true
    end
    
    it "returns false if errors does not contain the attribute" do
      expect(error.include?(:foo)).to be false
    end
  end
  
  describe "#[](attribute)" do
    let(:error){ Bodhi::Errors.new({test: ["no worky!", "another error!"]}) }
    
    it "returns an array of error messages if the attribute exists" do
      expect(error[:test]).to match_array(["no worky!", "another error!"])
      expect(error["test"]).to match_array(["no worky!", "another error!"])
    end
    
    it "returns nil if the attribute does not exist" do
      expect(error[:foo]).to be_nil
      expect(error["foo"]).to be_nil
    end
  end
  
  describe "#size" do
    let(:error){ Bodhi::Errors.new({test: ["no worky!", "another error!"]}) }
    
    it "returns the number of error messages" do
      expect(error.size).to eq 2
      error.clear
      expect(error.size).to eq 0
    end
  end
  
  describe "#empty?" do
    it "returns true if no errors are present" do
      error = Bodhi::Errors.new
      expect(error.empty?).to be true
    end
    
    it "returns false if errors are present" do
      error = Bodhi::Errors.new({test: ["no worky!", "another error!"]})
      expect(error.empty?).to be false
    end
  end
end