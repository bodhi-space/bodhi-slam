require 'spec_helper'

describe BodhiSlam do
  describe ".context" do
    context "with valid params" do
      it "should yield a Bodhi::Context" do
        BodhiSlam.context({ server: "http://google.com", namespace: "test" }) do |context|
          expect(context).to be_a Bodhi::Context
          expect(context).to be_valid
        end
      end
    end
    
    context "with invalid params" do
      it "should raise a Bodhi::Errors" do
        expect{ BodhiSlam.context({ server: nil, namespace: nil }){|context|} }.to raise_error(Bodhi::Errors)
        
        begin
          BodhiSlam.context({ server: nil, namespace: nil }){|context|}
        rescue Exception => e
          expect(e.messages[:server]).to match_array(["must be present", "must be a string", "must be a valid URI"])
          expect(e.messages[:namespace]).to match_array(["must be present", "must be a string"])
        end
      end
    end
  end
  
  describe ".analyze" do
    context "with valid context" do
      it "should create new classes & factories"
    end
    
    context "with invalid context" do
      let(:context){ Bodhi::Context.new({ server: nil, namespace: nil }) }
      
      it "should raise a Bodhi::Errors" do
        expect{ BodhiSlam.analyze(context) }.to raise_error(Bodhi::Errors)
      end
    end
  end
end