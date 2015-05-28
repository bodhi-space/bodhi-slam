require 'spec_helper'

describe BodhiSlam do
  describe ".context" do
    context "with valid params" do
      it "should yield a Bodhi::Context" do
        expect { |block| BodhiSlam.context({ server: "http://google.com", namespace: "test" }, &block) }.to yield_with_args(Bodhi::Context)
      end
    end
    
    context "with invalid params" do
      it "should raise a Bodhi::Errors" do
        expect{ BodhiSlam.context({ server: "test", namespace: "test" }){|context|} }.to raise_error(Bodhi::Errors)
        
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
  
  describe ".create_type" do
    it "should accept a hash of the type as a parameter" do
      expect{ BodhiSlam.create_type("invalid_param", []) }.to raise_error("Expected type to be a Hash")
    end
    
    it "should accept an array of enumerations as a parameter" do
      expect{ BodhiSlam.create_type({}, "invalid_param") }.to raise_error("Expected enumerations to be an Array")
    end
    
    context "with valid parameters" do
      let(:valid_type_hash){ { name: "TestType", package: "test", properties: { foo:{ type: "String"}, bar:{ type: "String" } } } }
      let(:valid_enum_array){ [] }
      
      it "should return the newly created class" do
        klass = BodhiSlam.create_type(valid_type_hash, valid_enum_array)
        expect(klass).to be_a Class
        expect(klass.name).to eq "TestType"
      end
    end
  end
  
  describe ".create_factory" do
    it "should accept a hash of the type as a parameter" do
      expect{ BodhiSlam.create_factory("invalid_param", []) }.to raise_error("Expected type to be a Hash")
    end
    
    it "should accept an array of enumerations as a parameter" do
      expect{ BodhiSlam.create_factory({}, "invalid_param") }.to raise_error("Expected enumerations to be an Array")
    end
    
    context "with valid parameters" do
      let(:valid_type_hash){ { name: "TestType", package: "test", properties: { foo:{ type: "String"}, bar:{ type: "String" } } } }
      let(:valid_enum_array){ [] }
      
      it "should return true" do
        expect(BodhiSlam.create_factory(valid_type_hash, valid_enum_array)).to be true
      end
    end
  end
  
  describe ".get_types" do
    context "with valid context" do
      let(:context){ Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: ENV['QA_TEST_COOKIE'] }) }
      
      it "should return an array of all types in a namespace" do
        expect(BodhiSlam.get_types(context)).to be_a Array
      end
    end
    
    context "with invalid authorization" do
      let(:context){ Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: "12345" }) }
      
      it "should raise an authentication.credentials.required error" do
        expect{ BodhiSlam.get_types(context) }.to raise_error(RuntimeError, '{"authentication.credentials.required"=>"Authentication failed", "authentication.supported.types"=>"HTTP_COOKIE, HTTP_BASIC", "status"=>401}')
      end
    end
    
    context "with invalid context" do
      let(:context){ Bodhi::Context.new({ server: nil, namespace: nil }) }
      
      it "should raise a Bodhi::Errors" do
        expect{ BodhiSlam.get_types(context) }.to raise_error(Bodhi::Errors)
      end
    end
  end
  
  describe ".get_enumerations" do
    context "with valid context" do
      let(:context){ Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: ENV['QA_TEST_COOKIE'] }) }
      
      it "should return an array of all enumerations in a namespace" do
        expect(BodhiSlam.get_enumerations(context)).to be_a Array
      end
    end
    
    context "with invalid authorization" do
      let(:context){ Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: "12345" }) }
      
      it "should raise an authentication.credentials.required error" do
        expect{ BodhiSlam.get_enumerations(context) }.to raise_error(RuntimeError, '{"authentication.credentials.required"=>"Authentication failed", "authentication.supported.types"=>"HTTP_COOKIE, HTTP_BASIC", "status"=>401}')
      end
    end
    
    context "with invalid context" do
      let(:context){ Bodhi::Context.new({ server: nil, namespace: nil }) }
      
      it "should raise a Bodhi::Errors" do
        expect{ BodhiSlam.get_enumerations(context) }.to raise_error(Bodhi::Errors)
      end
    end
  end
end