require 'spec_helper'

describe Bodhi::Profile do
  let(:profile){ Bodhi::Profile.new }

  it "includes Bodhi::Validations" do
    expect(profile.class.ancestors).to include Bodhi::Validations
  end

  describe ".factory" do
    it "returns a Bodhi::Factory for creating Bodhi::Profiles" do
      expect(Bodhi::Profile.factory).to be_a Bodhi::Factory
    end

    describe "#build" do
      it "returns a valid Bodhi::Profile" do
        puts "\033[33mGenerated\033[0m: \033[36m#{Bodhi::Profile.factory.build.attributes}\033[0m"
        expect(Bodhi::Profile.factory.build).to be_a Bodhi::Profile
        expect(Bodhi::Profile.factory.build.valid?).to be true
      end
    end

    describe "#create" do
      let(:context){ Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: ENV['QA_TEST_COOKIE'] }) }

      it "saves a profile to the cloud and returns a Bodhi::Profile" do
        profile = Bodhi::Profile.factory.create(context, name: "TestProfile007", namespace: context.namespace, dml: { Store: { select: {} } })
        puts "\033[33mGenerated\033[0m: \033[36m#{profile.attributes}\033[0m"
        profile.delete!
      end
    end
  end

  describe ".find(context, profile_name)" do
    let(:context){ Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: ENV['QA_TEST_COOKIE'] }) }

    it "returns Bodhi::ContextErrors if context is invalid" do
      bad_context = Bodhi::Context.new({ server: nil, namespace: nil, cookie: nil })
      expect{ Bodhi::Profile.find(bad_context, "test") }.to raise_error(Bodhi::ContextErrors)
    end

    it "returns a Bodhi::Profile for the given profile_name" do
      Bodhi::Profile.factory.create(context, name: "TestProfile007", namespace: context.namespace, dml: { Store: { select: {} } })
      profile = Bodhi::Profile.find(context, "TestProfile007")
      expect(profile).to be_a Bodhi::Profile
      profile.delete!
    end
  end
end