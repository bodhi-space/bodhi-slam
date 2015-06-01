require 'spec_helper'

describe Bodhi::TypeFactory do
  
  after do
    FactoryGirl.factories.clear
  end
  
  describe ".create_type" do
    it "should accept a hash of the type as a parameter" do
      expect{ Bodhi::TypeFactory.create_type("invalid_param", []) }.to raise_error("Expected type to be a Hash")
    end
    
    it "should accept an array of enumerations as a parameter" do
      expect{ Bodhi::TypeFactory.create_type({}, "invalid_param") }.to raise_error("Expected enumerations to be an Array")
    end
    
    context "with valid parameters" do
      let(:valid_type_hash){ { name: "TestType", package: "test", properties: { foo:{ type: "String"}, bar:{ type: "Integer" } } } }
      let(:valid_enum_array){ [] }
      
      it "should return the newly created class" do
        klass = Bodhi::TypeFactory.create_type(valid_type_hash, valid_enum_array)
        expect(klass).to be_a Class
        expect(klass.name).to eq "TestType"
      end
    end
  end
  
  describe ".create_factory" do
    it "should accept a hash of the type as a parameter" do
      expect{ Bodhi::TypeFactory.create_factory("invalid_param", []) }.to raise_error("Expected type to be a Hash")
    end
    
    it "should accept an optional array of enumerations as a parameter" do
      expect{ Bodhi::TypeFactory.create_factory({}, "invalid_param") }.to raise_error("Expected enumerations to be an Array")
    end
    
    context "with valid parameters" do
      let(:type){ { name: "TestType", package: "test", properties: { foo:{ type: "String"}, bar:{ type: "String" } } } }
      let(:enums){ ["hello"] }
      
      it "should return true" do
        expect(Bodhi::TypeFactory.create_factory(type, enums)).to be true
      end
    end
    
    context "with GeoJSON properties" do
      context "and multi=true" do
        let(:type){ { name: "TestType", package: "test", properties: { foo:{ type: "GeoJSON", multi: true} } } }
        let(:klass){ Bodhi::TypeFactory.create_type(type, []) }
        
        it "should register the factory and return true" do
          expect(Bodhi::TypeFactory.create_factory(type)).to be true
        end
        
        it "should return 0..5 random GeoJSON objects in an Array" do
          Bodhi::TypeFactory.create_factory(type)
          obj = FactoryGirl.build(:TestType)
          expect(obj.foo).to be_a Array
          expect(obj.foo.size).to be_between(0,5)
          
          puts "Generated object was: #{obj.attributes}"
        end
      end
      
      context "and multi=false" do
        let(:type){ { name: "TestType", package: "test", properties: { foo:{ type: "GeoJSON"} } } }
      
        it "should register the factory and return true" do
          expect(Bodhi::TypeFactory.create_factory(type)).to be true
        end
        
        it "should return a random GeoJSON object" do
          Bodhi::TypeFactory.create_factory(type)
          obj = FactoryGirl.build(:TestType)
          
          expect(obj.foo).to be_a Hash
          expect(obj.foo).to have_key :type
          expect(obj.foo).to have_key :coordinates
          expect(obj.foo[:coordinates]).to be_a Array
          
          puts "Generated object was: #{obj.attributes}"
        end
      end
    end
    
    context "with Boolean properties" do
      context "and multi=true" do
        let(:type){ { name: "TestType", package: "test", properties: { foo:{ type: "Boolean", multi: true} } } }
      
        it "should register the factory and return true" do
          expect(Bodhi::TypeFactory.create_factory(type)).to be true
        end
        
        it "should return 0..5 random Booleans in an Array" do
          Bodhi::TypeFactory.create_factory(type)
          obj = FactoryGirl.build(:TestType)
          expect(obj.foo).to be_a Array
          expect(obj.foo.size).to be_between(0,5)
          
          puts "Generated object was: #{obj.attributes}"
        end
      end
      
      context "and multi=false" do
        let(:type){ { name: "TestType", package: "test", properties: { foo:{ type: "Boolean"} } } }
      
        it "should register the factory and return true" do
          expect(Bodhi::TypeFactory.create_factory(type)).to be true
        end
        
        it "should return a random Boolean" do
          Bodhi::TypeFactory.create_factory(type)
          obj = FactoryGirl.build(:TestType)
          
          expect(obj.foo).to_not be_nil
          
          puts "Generated object was: #{obj.attributes}"
        end
      end
    end
    
    context "with Enumerated properties" do
      context "and multi=true" do
        let(:type){ { name: "TestType", package: "test", properties: { foo:{ type: "Enumerated", multi: true} } } }
      
        it "should register the factory and return true" do
          expect(Bodhi::TypeFactory.create_factory(type)).to be true
        end
      end
      
      context "and multi=false" do
        let(:type){ { name: "TestType", package: "test", properties: { foo:{ type: "Enumerated", ref: "TestEnum.name"} } } }
      
        it "should register the factory and return true" do
          expect(Bodhi::TypeFactory.create_factory(type)).to be true
        end
      end
    end
    
    context "with Object properties" do
      context "and multi=true" do
        let(:type){ { name: "TestType", package: "test", properties: { foo:{ type: "Object", multi: true} } } }
      
        it "should register the factory and return true" do
          expect(Bodhi::TypeFactory.create_factory(type)).to be true
        end
      end
      
      context "and multi=false" do
        let(:type){ { name: "TestType", package: "test", properties: { foo:{ type: "Object"} } } }
      
        it "should register the factory and return true" do
          expect(Bodhi::TypeFactory.create_factory(type)).to be true
        end
      end
    end
    
    context "with String properties" do
      context "and multi=true" do
        let(:type){ { name: "TestType", package: "test", properties: { foo:{ type: "String", multi: true} } } }
      
        it "should register the factory and return true" do
          expect(Bodhi::TypeFactory.create_factory(type)).to be true
        end
        
        it "should return 0..5 random Strings in an Array" do
          Bodhi::TypeFactory.create_factory(type)
          obj = FactoryGirl.build(:TestType)
          
          expect(obj.foo).to be_a Array
          expect(obj.foo.size).to be_between(0,5)
          expect(obj.foo[0]).to be_a String if obj.foo.size > 0
          
          puts "Generated object was: #{obj.attributes}"
        end
      end
      
      context "and multi=false" do
        let(:type){ { name: "TestType", package: "test", properties: { foo:{ type: "String"} } } }
      
        it "should register the factory and return true" do
          expect(Bodhi::TypeFactory.create_factory(type)).to be true
        end
        
        it "should return a random String" do
          Bodhi::TypeFactory.create_factory(type)
          obj = FactoryGirl.build(:TestType)
          
          expect(obj.foo).to be_a String
          
          puts "Generated object was: #{obj.attributes}"
        end
      end
    end
    
    context "with DateTime properties" do
      context "and multi=true" do
        let(:type){ { name: "TestType", package: "test", properties: { foo:{ type: "DateTime", multi: true} } } }
      
        it "should register the factory and return true" do
          expect(Bodhi::TypeFactory.create_factory(type)).to be true
        end
        
        it "should return 0..5 random DateTimes as Strings in an Array" do
          Bodhi::TypeFactory.create_factory(type)
          obj = FactoryGirl.build(:TestType)
          
          expect(obj.foo).to be_a Array
          expect(obj.foo.size).to be_between(0,5)
          expect(Time.parse(obj.foo[0])).to be_a Time if obj.foo.size > 0
          
          puts "Generated object was: #{obj.attributes}"
        end
      end
      
      context "and multi=false" do
        let(:type){ { name: "TestType", package: "test", properties: { foo:{ type: "DateTime"} } } }
      
        it "should register the factory and return true" do
          expect(Bodhi::TypeFactory.create_factory(type)).to be true
        end
        
        it "should return a random DateTime as a String" do
          Bodhi::TypeFactory.create_factory(type)
          obj = FactoryGirl.build(:TestType)
          
          expect(Time.parse(obj.foo)).to be_a Time
          
          puts "Generated object was: #{obj.attributes}"
        end
      end
    end
    
    context "with Integer properties" do
      context "and multi=true" do
        let(:type){ { name: "TestType", package: "test", properties: { foo:{ type: "Integer", multi: true} } } }
      
        it "should register the factory and return true" do
          expect(Bodhi::TypeFactory.create_factory(type)).to be true
        end
        
        it "should return 0..5 random Integers in an Array" do
          Bodhi::TypeFactory.create_factory(type)
          obj = FactoryGirl.build(:TestType)
          
          expect(obj.foo).to be_a Array
          expect(obj.foo.size).to be_between(0,5)
          expect(obj.foo[0]).to be_a Integer if obj.foo.size > 0
          
          puts "Generated object was: #{obj.attributes}"
        end
      end
      
      context "and multi=false" do
        let(:type){ { name: "TestType", package: "test", properties: { foo:{ type: "Integer"} } } }
      
        it "should register the factory and return true" do
          expect(Bodhi::TypeFactory.create_factory(type)).to be true
        end
        
        it "should return a random Integer" do
          Bodhi::TypeFactory.create_factory(type)
          obj = FactoryGirl.build(:TestType)
          
          expect(obj.foo).to be_a Integer
          
          puts "Generated object was: #{obj.attributes}"
        end
      end
    end
    
    context "with Real (Float) properties" do
      context "and multi=true" do
        let(:type){ { name: "TestType", package: "test", properties: { foo:{ type: "Real", multi: true} } } }
      
        it "should register the factory and return true" do
          expect(Bodhi::TypeFactory.create_factory(type)).to be true
        end
        
        it "should return 0..5 random Reals (Floats) in an Array" do
          Bodhi::TypeFactory.create_factory(type)
          obj = FactoryGirl.build(:TestType)
          
          expect(obj.foo).to be_a Array
          expect(obj.foo.size).to be_between(0,5)
          expect(obj.foo[0]).to be_a Float if obj.foo.size > 0
          
          puts "Generated object was: #{obj.attributes}"
        end
      end
      
      context "and multi=false" do
        let(:type){ { name: "TestType", package: "test", properties: { foo:{ type: "Real"} } } }
      
        it "should register the factory and return true" do
          expect(Bodhi::TypeFactory.create_factory(type)).to be true
        end
        
        it "should return a random Real (Float)" do
          Bodhi::TypeFactory.create_factory(type)
          obj = FactoryGirl.build(:TestType)
          
          expect(obj.foo).to be_a Float
          
          puts "Generated object was: #{obj.attributes}"
        end
      end
    end
    
    context "with Embedded properties" do
      context "and multi=true" do
        let(:type){ { name: "TestType", package: "test", properties: { foo:{ type: "TestEmbedded", multi: true} } } }
      
        it "should register the factory and return true" do
          expect(Bodhi::TypeFactory.create_factory(type)).to be true
        end
      end
      
      context "and multi=false" do
        let(:type){ { name: "TestType", package: "test", properties: { foo:{ type: "TestEmbedded"} } } }
      
        it "should register the factory and return true" do
          expect(Bodhi::TypeFactory.create_factory(type)).to be true
        end
      end
    end
  end
  
  describe ".get_types" do
    context "with valid context and authorization" do
      let(:context){ Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: ENV['QA_TEST_COOKIE'] }) }
      
      it "should return an array of all types in a namespace" do
        expect(Bodhi::TypeFactory.get_types(context)).to be_a Array
      end
    end
    
    context "with invalid authorization" do
      let(:context){ Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: "12345" }) }
      
      it "should raise an authentication.credentials.required error" do
        expect{ Bodhi::TypeFactory.get_types(context) }.to raise_error(RuntimeError, '{"authentication.credentials.required"=>"Authentication failed", "authentication.supported.types"=>"HTTP_COOKIE, HTTP_BASIC", "status"=>401}')
      end
    end
    
    context "with invalid context" do
      let(:context){ Bodhi::Context.new({ server: nil, namespace: nil }) }
      
      it "should raise a Bodhi::Errors" do
        expect{ Bodhi::TypeFactory.get_types(context) }.to raise_error(Bodhi::Errors)
      end
    end
  end
  
  describe ".get_enumerations" do
    context "with valid context and authorization" do
      let(:context){ Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: ENV['QA_TEST_COOKIE'] }) }
      
      it "should return an array of all enumerations in a namespace" do
        expect(Bodhi::TypeFactory.get_enumerations(context)).to be_a Array
      end
    end
    
    context "with invalid authorization" do
      let(:context){ Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: "12345" }) }
      
      it "should raise an authentication.credentials.required error" do
        expect{ Bodhi::TypeFactory.get_enumerations(context) }.to raise_error(RuntimeError, '{"authentication.credentials.required"=>"Authentication failed", "authentication.supported.types"=>"HTTP_COOKIE, HTTP_BASIC", "status"=>401}')
      end
    end
    
    context "with invalid context" do
      let(:context){ Bodhi::Context.new({ server: nil, namespace: nil }) }
      
      it "should raise a Bodhi::Errors" do
        expect{ Bodhi::TypeFactory.get_enumerations(context) }.to raise_error(Bodhi::Errors)
      end
    end
  end
end