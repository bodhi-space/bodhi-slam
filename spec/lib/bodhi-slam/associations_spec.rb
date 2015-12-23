require 'spec_helper'

describe Bodhi::Associations do
  before(:each) do
    @trainer = Object.const_set("Trainer", Class.new{ include Bodhi::Associations })
    @pokemon = Object.const_set("Pokemon", Class.new{ include Bodhi::Associations })
  end

  after(:each) do
    Object.send(:remove_const, :Trainer)
    Object.send(:remove_const, :Pokemon)
  end

  describe ".associations" do
    it "returns a Hash" do
      expect(@trainer.associations).to be_a Hash
    end

    it "has the key :has_one" do
      expect(@trainer.associations[:has_one]).to be_a Hash
    end

    it "has the key :has_many" do
      expect(@trainer.associations[:has_many]).to be_a Hash
    end

    it "has the key :belongs_to" do
      expect(@trainer.associations[:belongs_to]).to be_a Hash
    end
  end

  describe "valid association_name formats" do
    it "includes Strings" do
      @trainer.has_one("pokemon")
      expect(@trainer.associations[:has_one]).to have_key :pokemon
    end

    it "includes Symbols" do
      @trainer.has_one(:pokemon)
      expect(@trainer.associations[:has_one]).to have_key :pokemon
    end
  end

  describe "valid options" do
    it "can be Hash with String keys" do
      @trainer.has_one(:pokemon, "resource_name" => "Pokemon")
      expect(@trainer.associations[:has_one][:pokemon]).to have_key :resource_name
      expect(@trainer.associations[:has_one][:pokemon][:resource_name]).to eq "Pokemon"
    end

    it "accepts :query" do
      @trainer.has_one(:pokemon, query: { name: "Pikachu" })
      expect(@trainer.associations[:has_one][:pokemon]).to have_key :query
      expect(@trainer.associations[:has_one][:pokemon][:query]).to have_key :name
    end

    it "accepts :foreign_key" do
      @trainer.has_one(:pokemon, foreign_key: "super_trainer_id")
      expect(@trainer.associations[:has_one][:pokemon]).to have_key :foreign_key
      expect(@trainer.associations[:has_one][:pokemon][:foreign_key]).to eq "super_trainer_id"
    end

    it "accepts :resource_name" do
      @trainer.has_one(:pokemon, resource_name: "Pokemon")
      expect(@trainer.associations[:has_one][:pokemon]).to have_key :resource_name
      expect(@trainer.associations[:has_one][:pokemon][:resource_name]).to eq "Pokemon"
    end

    it "accepts :source_key" do
      @trainer.has_one(:pokemon, source_key: "name")
      expect(@trainer.associations[:has_one][:pokemon]).to have_key :source_key
      expect(@trainer.associations[:has_one][:pokemon][:source_key]).to eq "name"
    end
  end

  describe "default queries" do
    it "uses the calling objects sys_id" do
      @trainer.has_one(:pokemon)
      expect(@trainer.associations[:has_one][:pokemon][:query]).to eq trainer_id: "object.sys_id"
    end

    it "uses association_name for resource_name" do
      @trainer.has_one(:pokemon)
      expect(@trainer.associations[:has_one][:pokemon][:resource_name]).to eq "Pokemon"
    end

    it "uses the calling objects name plus _id for foreign_key" do
      @trainer.has_one(:pokemon)
      expect(@trainer.associations[:has_one][:pokemon][:foreign_key]).to eq "trainer_id"
    end
  end

  describe "customized queries" do
    it "updates the query based on the supplied :foreign_key" do
      @trainer.has_one(:pokemon, foreign_key: "backup_trainer_name")

      expect(@trainer.associations[:has_one][:pokemon][:query]).to eq backup_trainer_name: "object.sys_id"
      expect(@trainer.associations[:has_one][:pokemon][:source_key]).to eq "sys_id"
      expect(@trainer.associations[:has_one][:pokemon][:foreign_key]).to eq "backup_trainer_name"
      expect(@trainer.associations[:has_one][:pokemon][:resource_name]).to eq "Pokemon"
    end

    it "updates the query based on the supplied :source_property" do
      @trainer.has_one(:pokemon, source_key: "name")

      expect(@trainer.associations[:has_one][:pokemon][:query]).to eq trainer_id: "object.name"
      expect(@trainer.associations[:has_one][:pokemon][:source_key]).to eq "name"
      expect(@trainer.associations[:has_one][:pokemon][:foreign_key]).to eq "trainer_id"
      expect(@trainer.associations[:has_one][:pokemon][:resource_name]).to eq "Pokemon"
    end

    it "updates the query based on the supplied :resource_name" do
      @trainer.has_one(:pikachu, resource_name: "Pokemon")

      expect(@trainer.associations[:has_one][:pikachu][:query]).to eq trainer_id: "object.sys_id"
      expect(@trainer.associations[:has_one][:pikachu][:source_key]).to eq "sys_id"
      expect(@trainer.associations[:has_one][:pikachu][:foreign_key]).to eq "trainer_id"
      expect(@trainer.associations[:has_one][:pikachu][:resource_name]).to eq "Pokemon"
    end

    it "with custom :foreign_key, :source_key, :resource_name, and :query" do
      @trainer.has_one(:pikachu, resource_name: "Pokemon", source_key: "name", foreign_key: "trainer_name", query: { name: "Pikachu" })

      expect(@trainer.associations[:has_one][:pikachu][:query]).to eq trainer_name: "object.name", name: "Pikachu"
      expect(@trainer.associations[:has_one][:pikachu][:source_key]).to eq "name"
      expect(@trainer.associations[:has_one][:pikachu][:foreign_key]).to eq "trainer_name"
      expect(@trainer.associations[:has_one][:pikachu][:resource_name]).to eq "Pokemon"
    end
  end

  describe ".has_one(association_name, options={})" do
    it "auto-generates an instance method with the given association_name" do
      @trainer.has_one(:pokemon)
      expect(@trainer.new).to respond_to :pokemon
    end

    it "auto-generated instance method can be called and returns the target resource" do
      @context = Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: ENV['QA_TEST_COOKIE'] })

      @trainer.include(Bodhi::Resource)
      @trainer.property :name, type: "String"
      @trainer.has_one :pokemon

      trainer_type = @trainer.build_type
      trainer_type.bodhi_context = @context
      trainer_type.save!

      @pokemon.include(Bodhi::Resource)
      @pokemon.property :name, type: "String"
      @pokemon.property :trainer_id, type: "String", is_not_blank: true
      @pokemon.index [:trainer_id], unique: true

      pokemon_type = @pokemon.build_type
      pokemon_type.bodhi_context = @context
      pokemon_type.save!

      ash = @trainer.factory.create(bodhi_context: @context, name: "Ash Ketchum")
      pikachu = @pokemon.factory.create(bodhi_context: @context, name: "Pikachu", trainer_id: ash.id)

      # Finally! The actual tests...
      pokemon = ash.pokemon
      puts pokemon.attributes
      expect(pokemon).to be_a Pokemon
      expect(pokemon.name).to eq "Pikachu"

      # Clean up!
      trainer_type.delete!
      pokemon_type.delete!
    end
  end

  describe ".has_many(association_name, options={})" do
    it "auto-generates an instance method with the given association_name" do
      @trainer.has_many(:pokemon)
      expect(@trainer.new).to respond_to :pokemon
    end

    it "auto-generated instance method can be called and returns the target resources" do
      @context = Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: ENV['QA_TEST_COOKIE'] })

      @trainer.include(Bodhi::Resource)
      @trainer.property :name, type: "String"
      @trainer.has_many :pokemon

      trainer_type = @trainer.build_type
      trainer_type.bodhi_context = @context
      trainer_type.save!

      @pokemon.include(Bodhi::Resource)
      @pokemon.property :name, type: "String"
      @pokemon.property :trainer_id, type: "String", is_not_blank: true

      pokemon_type = @pokemon.build_type
      pokemon_type.bodhi_context = @context
      pokemon_type.save!

      ash = @trainer.factory.create(bodhi_context: @context, name: "Ash Ketchum")
      pikachu = @pokemon.factory.create(bodhi_context: @context, name: "Pikachu", trainer_id: ash.id)
      bulbasaur = @pokemon.factory.create(bodhi_context: @context, name: "Bulbasaur", trainer_id: ash.id)
      charmander = @pokemon.factory.create(bodhi_context: @context, name: "Charmander", trainer_id: ash.id)

      # Finally! The actual tests...
      pokemon = ash.pokemon
      puts pokemon.map(&:attributes).to_s
      pokemon.each{ |item| expect(item).to be_a Pokemon }

      # Clean up!
      trainer_type.delete!
      pokemon_type.delete!
    end
  end
end