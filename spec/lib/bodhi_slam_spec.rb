require 'spec_helper'

describe BodhiSlam do
  describe ".context" do
    context "with valid params" do
      it "should yield a BodhiContext" do
        BodhiSlam.context({ server: "test", namespace: "test" }) do |context|
          expect(context).to be_a BodhiContext
          expect(context).to be_valid
        end
      end
    end
    
    context "with invalid params" do
      it "should raise a Bodhi::ContextError" do
        expect{ BodhiSlam.context({ server: nil, namespace: nil }){|context|} }.to raise_error(Bodhi::ContextError)
      end
    end
  end
  
  describe ".analyze" do
    context "with valid context" do
      it "should create new classes & factories"
    end
    
    context "with invalid context" do
      let(:context){ BodhiContext.new({ server: nil, namespace: nil }) }
      
      it "should raise a Bodhi::ContextError" do
        expect{ BodhiSlam.analyze(context) }.to raise_error(Bodhi::ContextError)
      end
    end
  end
end