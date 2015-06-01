require 'spec_helper'

describe Bodhi::Context do
  context "with invalid 'server' attribute" do
    let(:context){ Bodhi::Context.new({ server: nil, namespace: "test", username: "foo", password: "bar" }) }
    
    it "should return false" do
      expect(context).to_not be_valid
    end
    
    it "should add new error messages" do
      context.valid?
      expect(context.errors).to be_a Bodhi::Errors
      expect(context.errors.full_messages).to include("server is required")
      expect(context.errors.full_messages).to include("server must be a valid URL")
    end
  end

  context "with invalid 'namespace' attribute" do
    let(:context){ Bodhi::Context.new({ server: "http://google.com", namespace: nil, username: "foo", password: "bar" }) }
    
    it "should return false" do
      expect(context).to_not be_valid
    end
    
    it "should add new error messages" do
      context.valid?
      expect(context.errors).to be_a Bodhi::Errors
      expect(context.errors.full_messages).to include("namespace is required")
    end
  end
  
  context "with valid attributes" do
    it "should return true" do
      expect(Bodhi::Context.new({ server: "http://google.com", namespace: "test" })).to be_valid
    end
  end
  
  
  describe "#errors" do
    let(:context){ Bodhi::Context.new({ server: "http://google.com", namespace: "test", username: "foo", password: "bar" }) }
    
    it "should return a Bodhi::Errors object" do
      expect(context.errors).to be_a Bodhi::Errors
    end
  end
  
  describe "#attributes" do
    let(:context){ Bodhi::Context.new({ server: "http://google.com", namespace: "test", username: "foo", password: "bar" }) }
    
    it "should return a Hash of the context's attributes" do
      expect(context.attributes).to be_a Hash
      expect(context.attributes[:server]).to eq "http://google.com"
      expect(context.attributes[:namespace]).to eq "test"
    end
  end
  
  describe "#server" do
    let(:context){ Bodhi::Context.new({ server: "http://google.com", namespace: "test", username: "foo", password: "bar" }) }

    it "should return the server url" do
      expect(context.server).to be_a String
      expect(context.server).to eq "http://google.com"
    end
  end
  
  describe "#namespace" do
    let(:context){ Bodhi::Context.new({ server: "http://google.com", namespace: "test", username: "foo", password: "bar" }) }

    it "should return the namespace name" do
      expect(context.namespace).to be_a String
      expect(context.namespace).to eq "test"
    end
  end
  
  describe "#credentials" do
    let(:basic_auth){ Bodhi::Context.new({ server: "http://google.com", namespace: "test", username: "foo", password: "bar" }) }
    let(:cookie_auth){ Bodhi::Context.new({ server: "http://google.com", namespace: "test", cookie: "12345" }) }
    
    context "with basic authorization" do
      it "should return the basic auth credentials" do
        expect(basic_auth.credentials).to be_a String
        expect(basic_auth.credentials).to eq "Basic Zm9vOmJhcg=="
      end
    end
    
    context "with cookie authorization" do
      it "should return the cookie auth credentials" do
        expect(cookie_auth.credentials).to be_a String
        expect(cookie_auth.credentials).to eq "12345"
      end
    end
  end
  
  describe "#credentials_header" do
    let(:basic_auth){ Bodhi::Context.new({ server: "http://google.com", namespace: "test", username: "foo", password: "bar" }) }
    let(:cookie_auth){ Bodhi::Context.new({ server: "http://google.com", namespace: "test", cookie: "12345" }) }
    
    context "with basic auth" do
      it "should return the 'Authorization' header" do
        expect(basic_auth.credentials_header).to be_a String
        expect(basic_auth.credentials_header).to eq "Authorization"
      end
    end
    
    context "with cookie auth" do
      it "should return the 'Cookie' header" do
        expect(cookie_auth.credentials_header).to be_a String
        expect(cookie_auth.credentials_header).to eq "Cookie"
      end
    end
  end
  
  describe "#credentials_type" do
    let(:basic_auth){ Bodhi::Context.new({ server: "http://google.com", namespace: "test", username: "foo", password: "bar" }) }
    let(:cookie_auth){ Bodhi::Context.new({ server: "http://google.com", namespace: "test", cookie: "12345" }) }
    
    context "with basic auth" do
      it "should return HTTP_BASIC" do
        expect(basic_auth.credentials_type).to be_a String
        expect(basic_auth.credentials_type).to eq "HTTP_BASIC"
      end
    end
    
    context "with cookie auth" do
      it "should return HTTP_COOKIE" do
        expect(cookie_auth.credentials_type).to be_a String
        expect(cookie_auth.credentials_type).to eq "HTTP_COOKIE"
      end
    end
  end
end