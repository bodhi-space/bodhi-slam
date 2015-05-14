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
      it "should return an empty BodhiContext" do
        BodhiSlam.context({ server: nil, namespace: nil }) do |context|
          expect(context).to be_a BodhiContext
          expect(context).to be_valid
        end
      end
    end
  end
end