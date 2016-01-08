require 'spec_helper'

describe Bodhi::Associations do
  before(:each) do
    @pokeball = Object.const_set("Pokeball", Class.new{ include Bodhi::Associations })
    @trainer = Object.const_set("Trainer", Class.new{ include Bodhi::Associations })
    @pokedex = Object.const_set("Pokedex", Class.new{ include Bodhi::Associations })
    @pokemon = Object.const_set("Pokemon", Class.new{ include Bodhi::Associations })
  end

  after(:each) do
    Object.send(:remove_const, :Pokeball)
    Object.send(:remove_const, :Trainer)
    Object.send(:remove_const, :Pokedex)
    Object.send(:remove_const, :Pokemon)
  end

  describe ".associations" do
    it "returns a Hash" do
      expect(@trainer.associations).to be_a Hash
    end
  end

  describe "valid association_name formats" do
    it "includes Strings" do
      @trainer.has_one("pokemon")
      expect(@trainer.associations).to have_key :pokemon
    end

    it "includes Symbols" do
      @trainer.has_one(:pokemon)
      expect(@trainer.associations).to have_key :pokemon
    end
  end

  describe "valid options" do
    it "can be Hash with String keys" do
      @trainer.has_one(:pokemon, "class_name" => "Foo")
      expect(@trainer.associations[:pokemon]).to have_key :class_name
      expect(@trainer.associations[:pokemon][:class_name]).to eq "Foo"
    end

    it "accepts additional :query conditions" do
      @trainer.has_one(:pokemon, query: { name: "Pikachu" })
      expect(@trainer.associations[:pokemon]).to have_key :query
      expect(@trainer.associations[:pokemon][:query]).to eq name: "Pikachu"
    end

    it "accepts a :primary_key option" do
      @trainer.has_one(:pokemon, primary_key: "name")
      expect(@trainer.associations[:pokemon]).to have_key :primary_key
      expect(@trainer.associations[:pokemon][:primary_key]).to eq "name"
    end

    it "accepts a :foreign_key option" do
      @trainer.has_one(:pokemon, foreign_key: "super_trainer_id")
      expect(@trainer.associations[:pokemon]).to have_key :foreign_key
      expect(@trainer.associations[:pokemon][:foreign_key]).to eq "super_trainer_id"
    end

    it "accepts a :class_name option" do
      @trainer.has_one(:pokemon, class_name: "Pokemon")
      expect(@trainer.associations[:pokemon]).to have_key :class_name
      expect(@trainer.associations[:pokemon][:class_name]).to eq "Pokemon"
    end

    describe ":through" do
      context "as a Symbol" do
        it "sets the :through option in the assocaition to a symbol"
      end

      context "as a String" do
        it "sets the :through option in the association to the string (has_one)" do
          @trainer.has_one(:pokemon, through: "Pokedex")
          expect(@trainer.associations[:pokemon]).to have_key :through
          expect(@trainer.associations[:pokemon][:through][:class_name]).to eq "Pokedex"
          expect(@trainer.associations[:pokemon][:through][:primary_key]).to eq "sys_id"
          expect(@trainer.associations[:pokemon][:through][:foreign_key]).to eq "trainer_id"
        end

        it "sets the :through option in the association to the string (has_many)" do
          @trainer.has_many(:pokemon, through: "Pokedex")
          expect(@trainer.associations[:pokemon]).to have_key :through
          expect(@trainer.associations[:pokemon][:through][:class_name]).to eq "Pokedex"
          expect(@trainer.associations[:pokemon][:through][:primary_key]).to eq "pokemon_id"
          expect(@trainer.associations[:pokemon][:through][:foreign_key]).to eq "trainer_id"
        end
      end

      context "as a Hash" do
        it "accepts :class_name" do
          @trainer.has_one(:pokemon, through: { class_name: "Foo" })
          expect(@trainer.associations[:pokemon]).to have_key :through
          expect(@trainer.associations[:pokemon][:through][:class_name]).to eq "Foo"
        end

        it "accepts :primary_key" do
          @trainer.has_one(:pokemon, through: { primary_key: "trainer_name" })
          expect(@trainer.associations[:pokemon]).to have_key :through
          expect(@trainer.associations[:pokemon][:through][:primary_key]).to eq "trainer_name"
        end

        it "accepts :foreign_key" do
          @trainer.has_one(:pokemon, through: { foreign_key: "pokemon_name" })
          expect(@trainer.associations[:pokemon]).to have_key :through
          expect(@trainer.associations[:pokemon][:through][:foreign_key]).to eq "pokemon_name"
        end
      end
    end
  end

  describe "default queries" do
    it "uses the calling objects sys_id" do
      @trainer.has_one(:pokemon)
      expect(@trainer.associations[:pokemon][:primary_key]).to eq "sys_id"
    end

    it "uses association_name for resource_name" do
      @trainer.has_one(:pokemon)
      expect(@trainer.associations[:pokemon][:class_name]).to eq "Pokemon"
    end

    it "uses the calling objects name plus _id for foreign_key" do
      @trainer.has_one(:pokemon)
      expect(@trainer.associations[:pokemon][:foreign_key]).to eq "trainer_id"
    end
  end

  describe "customized queries" do
    it "updates the query based on the supplied :foreign_key" do
      @trainer.has_one(:pokemon, foreign_key: "backup_trainer_name")

      expect(@trainer.associations[:pokemon][:primary_key]).to eq "sys_id"
      expect(@trainer.associations[:pokemon][:foreign_key]).to eq "backup_trainer_name"
      expect(@trainer.associations[:pokemon][:class_name]).to eq "Pokemon"
    end

    it "updates the query based on the supplied :source_property" do
      @trainer.has_one(:pokemon, primary_key: "name")

      expect(@trainer.associations[:pokemon][:primary_key]).to eq "name"
      expect(@trainer.associations[:pokemon][:foreign_key]).to eq "trainer_id"
      expect(@trainer.associations[:pokemon][:class_name]).to eq "Pokemon"
    end

    it "updates the query based on the supplied :class_name" do
      @trainer.has_one(:pikachu, class_name: "Pokemon")

      expect(@trainer.associations[:pikachu][:primary_key]).to eq "sys_id"
      expect(@trainer.associations[:pikachu][:foreign_key]).to eq "trainer_id"
      expect(@trainer.associations[:pikachu][:class_name]).to eq "Pokemon"
    end

    it "with custom :foreign_key, :primary_key, :class_name, and :query" do
      @trainer.has_one(:pikachu, class_name: "Pokemon", primary_key: "name", foreign_key: "trainer_name", query: { name: "Pikachu" })

      expect(@trainer.associations[:pikachu][:query]).to eq name: "Pikachu"
      expect(@trainer.associations[:pikachu][:primary_key]).to eq "name"
      expect(@trainer.associations[:pikachu][:foreign_key]).to eq "trainer_name"
      expect(@trainer.associations[:pikachu][:class_name]).to eq "Pokemon"
    end
  end

  describe ".has_one(association_name, options={})" do
    it "sets the association type to :has_one" do
      @trainer.has_one(:pokemon)
      expect(@trainer.associations[:pokemon]).to have_key :association_type
      expect(@trainer.associations[:pokemon][:association_type]).to eq :has_one
    end

    it "auto-generates an instance method with the given association_name" do
      @trainer.has_one(:pokemon)
      expect(@trainer.new).to respond_to :pokemon
    end

    context "auto-generated GET method" do
      it "returns all associated objects (default options)" do
        @context = Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: ENV['QA_TEST_COOKIE'] })

        @trainer.include(Bodhi::Resource)
        @trainer.property :name, type: "String"
        @trainer.has_one :pokemon
        puts "@trainer.has_one :pokemon"

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

      it "returns all associated objects (custom options)" do
        @context = Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: ENV['QA_TEST_COOKIE'] })

        @trainer.include(Bodhi::Resource)
        @trainer.property :name, type: "String"
        @trainer.has_one :starter_pokemon, class_name: "Pokemon", primary_key: "name", foreign_key: "trainer_name"
        puts '@trainer.has_one :starter_pokemon, class_name: "Pokemon", primary_key: "name", foreign_key: "trainer_name"'

        trainer_type = @trainer.build_type
        trainer_type.bodhi_context = @context
        trainer_type.save!

        @pokemon.include(Bodhi::Resource)
        @pokemon.property :name, type: "String"
        @pokemon.property :trainer_name, type: "String", is_not_blank: true
        @pokemon.index [:trainer_name], unique: true

        pokemon_type = @pokemon.build_type
        pokemon_type.bodhi_context = @context
        pokemon_type.save!

        ash = @trainer.factory.create(bodhi_context: @context, name: "Ash Ketchum")
        bulbasaur = @pokemon.factory.create(bodhi_context: @context, name: "Pikachu", trainer_name: ash.name)

        # Finally! The actual tests...
        pokemon = ash.starter_pokemon
        puts pokemon.attributes
        expect(pokemon).to be_a Pokemon
        expect(pokemon.name).to eq "Pikachu"

        # Clean up!
        trainer_type.delete!
        pokemon_type.delete!
      end

      it "returns all assocaited objects :through the given association" do
        @context = Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: ENV['QA_TEST_COOKIE'] })

        @trainer.include(Bodhi::Resource)
        @trainer.property :name, type: "String"
        @trainer.has_one :pokemon, through: "Pokedex"
        puts '@trainer.has_one :pokemon, through: "Pokedex"'

        trainer_type = @trainer.build_type
        trainer_type.bodhi_context = @context
        trainer_type.save!

        @pokedex.include(Bodhi::Resource)
        @pokedex.property :name, type: "String"
        @pokedex.property :trainer_id, type: "String", is_not_blank: true

        pokedex_type = @pokedex.build_type
        pokedex_type.bodhi_context = @context
        pokedex_type.save!

        @pokemon.include(Bodhi::Resource)
        @pokemon.property :name, type: "String"
        @pokemon.property :pokedex_id, type: "String", is_not_blank: true

        pokemon_type = @pokemon.build_type
        pokemon_type.bodhi_context = @context
        pokemon_type.save!

        ash = @trainer.factory.create(bodhi_context: @context, name: "Ash Ketchum")
        pokedex = @pokedex.factory.create(bodhi_context: @context, name: "Ash Ketchum's Pokedex", trainer_id: ash.id)
        pikachu = @pokemon.factory.create(bodhi_context: @context, name: "Pikachu", pokedex_id: pokedex.id)

        # Finally! The actual tests...
        pokemon = ash.pokemon
        puts pokemon.attributes
        expect(pokemon).to be_a Pokemon
        expect(pokemon.name).to eq "Pikachu"

        # Clean up!
        trainer_type.delete!
        pokedex_type.delete!
        pokemon_type.delete!
      end
    end
  end

  describe ".has_many(association_name, options={})" do
    it "sets the association type to :has_many" do
      @trainer.has_many(:pokemon)
      expect(@trainer.associations[:pokemon]).to have_key :association_type
      expect(@trainer.associations[:pokemon][:association_type]).to eq :has_many
    end

    it "auto-generates an instance method with the given association_name" do
      @trainer.has_many(:pokemon)
      expect(@trainer.new).to respond_to :pokemon
    end

    context "auto-generated GET method" do
      it "returns all associated objects (array of ids)" do
        @context = Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: ENV['QA_TEST_COOKIE'] })

        @trainer.include(Bodhi::Resource)
        @trainer.property :name, type: "String"
        @trainer.property :pokemon_ids, type: "String", multi: true
        @trainer.has_many :pokemon, primary_key: "pokemon_ids", foreign_key: "sys_id"
        puts '@trainer.property :pokemon_ids, type: "String", multi: true'
        puts '@trainer.has_many :pokemon, primary_key: "pokemon_ids", foreign_key: "sys_id"'

        trainer_type = @trainer.build_type
        trainer_type.bodhi_context = @context
        trainer_type.save!

        @pokemon.include(Bodhi::Resource)
        @pokemon.property :name, type: "String"

        pokemon_type = @pokemon.build_type
        pokemon_type.bodhi_context = @context
        pokemon_type.save!

        ash = @trainer.factory.create(bodhi_context: @context, name: "Ash Ketchum")
        squirtle = @pokemon.factory.create(bodhi_context: @context, name: "Squirtle")
        bulbasaur = @pokemon.factory.create(bodhi_context: @context, name: "Bulbasaur")
        charmander = @pokemon.factory.create(bodhi_context: @context, name: "Charmander")

        #ash.patch! [{ op: "add", path: "/pokemon_ids", value: [squirtle.id, bulbasaur.id] }]
        ash.update! pokemon_ids: [squirtle.id, bulbasaur.id]

        # Finally! The actual tests...
        pokemon = ash.pokemon
        puts pokemon.map(&:attributes).to_s
        pokemon.each{ |item| expect(item).to be_a Pokemon }
        expect(pokemon.size).to eq 2

        # Clean up!
        trainer_type.delete!
        pokemon_type.delete!
      end

      it "returns all associated objects (default options)" do
        @context = Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: ENV['QA_TEST_COOKIE'] })

        @trainer.include(Bodhi::Resource)
        @trainer.property :name, type: "String"
        @trainer.has_many :pokemon
        puts '@trainer.has_many :pokemon'

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

      it "returns all associated objects (custom options)" do
        @context = Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: ENV['QA_TEST_COOKIE'] })

        @trainer.include(Bodhi::Resource)
        @trainer.property :name, type: "String"
        @trainer.has_many :fire_pokemon, class_name: "Pokemon", primary_key: "name", foreign_key: "trainer_name", query: { type: "Fire" }
        puts '@trainer.has_many :fire_pokemon, class_name: "Pokemon", primary_key: "name", foreign_key: "trainer_name", query: { type: "Fire" }'

        trainer_type = @trainer.build_type
        trainer_type.bodhi_context = @context
        trainer_type.save!

        @pokemon.include(Bodhi::Resource)
        @pokemon.property :name, type: "String"
        @pokemon.property :type, type: "String"
        @pokemon.property :trainer_name, type: "String", is_not_blank: true

        pokemon_type = @pokemon.build_type
        pokemon_type.bodhi_context = @context
        pokemon_type.save!

        ash = @trainer.factory.create(bodhi_context: @context, name: "Ash Ketchum")
        pikachu = @pokemon.factory.create(bodhi_context: @context, name: "Pikachu", type: "Electric", trainer_name: ash.name)
        flareon = @pokemon.factory.create(bodhi_context: @context, name: "Flareon", type: "Fire", trainer_name: ash.name)
        charmander = @pokemon.factory.create(bodhi_context: @context, name: "Charmander", type: "Fire", trainer_name: ash.name)

        # Finally! The actual tests...
        pokemon = ash.fire_pokemon
        puts pokemon.map(&:attributes).to_s
        pokemon.each{ |item| expect(item).to be_a Pokemon }

        # Clean up!
        trainer_type.delete!
        pokemon_type.delete!
      end

      it "returns all assocaited objects :through the given association" do
        @context = Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: ENV['QA_TEST_COOKIE'] })

        @trainer.include(Bodhi::Resource)
        @trainer.property :name, type: "String"
        @trainer.has_many :pokemon, through: "Pokeball"
        puts '@trainer.has_many :pokemon, through: "Pokeball"'

        trainer_type = @trainer.build_type
        trainer_type.bodhi_context = @context
        trainer_type.save!

        @pokemon.include(Bodhi::Resource)
        @pokemon.property :name, type: "String"
        @pokemon.has_many :trainers, class_name: "Trainer", through: "Pokeball"
        puts '@pokemon.has_many :trainers, class_name: "Trainer", through: "Pokeball"'

        pokemon_type = @pokemon.build_type
        pokemon_type.bodhi_context = @context
        pokemon_type.save!

        @pokeball.include(Bodhi::Resource)
        @pokeball.property :trainer_id, type: "String", is_not_blank: true
        @pokeball.property :pokemon_id, type: "String", is_not_blank: true

        pokeball_type = @pokeball.build_type
        pokeball_type.bodhi_context = @context
        pokeball_type.save!

        ash = @trainer.factory.create(bodhi_context: @context, name: "Ash Ketchum")
        broc = @trainer.factory.create(bodhi_context: @context, name: "Broc")

        pikachu = @pokemon.factory.create(bodhi_context: @context, name: "Pikachu")
        onix = @pokemon.factory.create(bodhi_context: @context, name: "Onix")

        pokeball_1 = @pokeball.factory.create(bodhi_context: @context, trainer_id: ash.id, pokemon_id: pikachu.id)
        pokeball_2 = @pokeball.factory.create(bodhi_context: @context, trainer_id: ash.id, pokemon_id: onix.id)
        pokeball_3 = @pokeball.factory.create(bodhi_context: @context, trainer_id: broc.id, pokemon_id: onix.id)

        # Finally! The actual tests...
        pokemon = ash.pokemon
        puts pokemon.map(&:attributes).to_s
        pokemon.each{ |item| expect(item).to be_a Pokemon }
        expect(pokemon.size).to eq 2

        trainers = onix.trainers
        puts trainers.map(&:attributes).to_s
        trainers.each{ |item| expect(item).to be_a Trainer }
        expect(trainers.size).to eq 2

        # Clean up!
        trainer_type.delete!
        pokemon_type.delete!
        pokeball_type.delete!
      end
    end
  end

  describe ".belongs_to(association_name, options={})" do
    it "sets the association type to :has_one" do
      @pokemon.belongs_to(:trainer)
      expect(@pokemon.associations[:trainer]).to have_key :association_type
      expect(@pokemon.associations[:trainer][:association_type]).to eq :belongs_to
    end

    it "auto-generates an instance method with the given association_name" do
      @pokemon.belongs_to(:trainer)
      expect(@pokemon.new).to respond_to :trainer
    end

    it "auto-generated instance method can be called and returns the target resources" do
      @context = Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: ENV['QA_TEST_COOKIE'] })

      @trainer.include(Bodhi::Resource)
      @trainer.property :name, type: "String"

      trainer_type = @trainer.build_type
      trainer_type.bodhi_context = @context
      trainer_type.save!

      @pokemon.include(Bodhi::Resource)
      @pokemon.property :name, type: "String"
      @pokemon.property :trainer_id, type: "String", is_not_blank: true
      @pokemon.belongs_to :trainer
      puts '@pokemon.belongs_to :trainer'

      pokemon_type = @pokemon.build_type
      pokemon_type.bodhi_context = @context
      pokemon_type.save!

      ash = @trainer.factory.create(bodhi_context: @context, name: "Ash Ketchum")
      pikachu = @pokemon.factory.create(bodhi_context: @context, name: "Pikachu", trainer_id: ash.id)

      # Finally! The actual tests...
      trainer = pikachu.trainer
      puts trainer.attributes
      expect(trainer).to be_a Trainer
      expect(trainer.name).to eq "Ash Ketchum"

      # Clean up!
      trainer_type.delete!
      pokemon_type.delete!
    end
  end
end