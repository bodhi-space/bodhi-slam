require 'spec_helper'

describe Bodhi::User do
  let(:user){ Bodhi::User.new }

  it "includes Bodhi::Validations" do
    expect(user.class.ancestors).to include Bodhi::Validations
  end

  describe ".factory" do
    it "returns a Bodhi::Factory for creating Bodhi::Users" do
      expect(Bodhi::User.factory).to be_a Bodhi::Factory
    end

    describe "#build" do
      it "returns a valid Bodhi::User" do
        puts "\033[33mGenerated\033[0m: \033[36m#{Bodhi::User.factory.build.attributes}\033[0m"
        expect(Bodhi::User.factory.build).to be_a Bodhi::User
        expect(Bodhi::User.factory.build.valid?).to be true
      end
    end

    describe "#create" do
      let(:context){ Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: ENV['QA_TEST_COOKIE'] }) }

      it "saves a user to the cloud and returns Bodhi::User" do
        user = Bodhi::User.factory.create(context, username: "AutoTest_24601", password: "12345", email: "test@email.com", profiles: ["user"])
        puts "\033[33mGenerated\033[0m: \033[36m#{user.attributes}\033[0m"
        expect(user.username).to eq "AutoTest_24601"

        user_context = Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], username: "AutoTest_24601", password: "12345" })
        user.bodhi_context = user_context
        user.delete!
      end
    end
  end

  describe ".find(context, user_name)" do
    let(:context){ Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: ENV['QA_TEST_COOKIE'] }) }

    it "returns Bodhi::ContextErrors if context is invalid" do
      bad_context = Bodhi::Context.new({ server: nil, namespace: nil, cookie: nil })
      expect{ Bodhi::User.find(bad_context, "test") }.to raise_error(Bodhi::ContextErrors)
    end

    it "returns a Bodhi::User for the given user_name" do
      Bodhi::User.factory.create(context, username: "autotest_user1", password: "12345", email: "test@email.com", profiles: ["user"])
      user = Bodhi::User.find(context, "autotest_user1")
      expect(user).to be_a Bodhi::User

      # Clean up the created user
      user_context = Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], username: "autotest_user1", password: "12345" })
      user.bodhi_context = user_context
      user.delete!
    end
  end

  describe ".find_me(context)" do
    let(:context){ Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: ENV['QA_TEST_COOKIE'] }) }

    it "returns Bodhi::ContextErrors if context is invalid" do
      bad_context = Bodhi::Context.new({ server: nil, namespace: nil, cookie: nil })
      expect{ Bodhi::User.find_me(bad_context) }.to raise_error(Bodhi::ContextErrors)
    end

    it "returns JSON for the given user context" do
      user = Bodhi::User.find_me(context)
      expect(user).to be_a Hash
      puts "\033[33mReturned\033[0m: \033[36m#{user}\033[0m"
    end
  end

  describe "#username" do
    let(:user){ Bodhi::User.new({ username: "test" }) }

    it "must be present" do
      user.username = nil
      expect(user.valid?).to be false
      expect(user.errors.include?(:username)).to be true
      expect(user.errors[:username]).to include "is required"
    end

    it "can not be blank" do
      user.username = ""
      expect(user.valid?).to be false
      expect(user.errors.include?(:username)).to be true
      expect(user.errors[:username]).to include "can not be blank"
    end
  end

  describe "#password" do
    let(:user){ Bodhi::User.new({ password: "test" }) }

    it "must be present" do
      user.password = nil
      expect(user.valid?).to be false
      expect(user.errors.include?(:password)).to be true
      expect(user.errors[:password]).to include "is required"
    end

    it "can not be blank" do
      user.password = ""
      expect(user.valid?).to be false
      expect(user.errors.include?(:password)).to be true
      expect(user.errors[:password]).to include "can not be blank"
    end
  end

  describe "#profiles" do
    let(:user){ Bodhi::User.new({ profiles: ["test"] }) }

    it "must be present" do
      user.profiles = nil
      expect(user.valid?).to be false
      expect(user.errors.include?(:profiles)).to be true
      expect(user.errors[:profiles]).to include "is required"
    end

    it "must be an array" do
      user.profiles = "test"
      expect(user.valid?).to be false
      expect(user.errors.include?(:profiles)).to be true
      expect(user.errors[:profiles]).to include "must be an array"
    end
  end

  describe "#email" do
    let(:user){ Bodhi::User.new({ email: "1234" }) }

    it "must be an email address" do
      expect(user.valid?).to be false
      expect(user.errors.include?(:email)).to be true
      expect(user.errors[:email]).to include "must be a valid email address"
    end
  end
end