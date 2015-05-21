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

    describe "#any?" do
      context "with errors present" do
        it "should return true" do
          expect(error.messages.any?).to be true
        end
      end
      
      context "with no errors present" do
        let(:error){ Bodhi::Errors.new }

        it "should return false" do
          expect(error.messages.any?).to be false
        end
      end
    end

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
    
    describe "#any?" do
      context "with errors present" do
        let(:error){ Bodhi::Errors.new({test: ["foo", "bar"]}) }

        it "should return true" do
          expect(error.full_messages.any?).to be true
        end
      end
      
      context "with no errors present" do
        let(:error){ Bodhi::Errors.new }

        it "should return false" do
          expect(error.full_messages.any?).to be false
        end
      end
    end
    
    it "returns an array" do
      expect(error.full_messages).to be_a Array
    end
    
    it "includes each error with a full description" do
      expect(error.full_messages).to match_array(["test no worky!", "test another error!"])
    end
  end
  
  describe "#to_json" do
    let(:error){ Bodhi::Errors.new({test: ["no worky!", "another error!"]}) }
    
    it "should return the messages hash in json format" do
      expect(error.to_json).to be_a String
      expect(error.to_json).to eq "{\"test\":[\"no worky!\",\"another error!\"]}"
    end
  end
end