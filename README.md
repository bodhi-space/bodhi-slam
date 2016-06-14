# bodhi-slam
bodhi-slam is an ORM for the Bodhi API which provides a simple DSL for interacting with resources in the cloud.

## Compatiblity
bodhi-slam has been tested on: MRI Ruby 2.0, 2.1, 2.2, and JRuby 9.0.0

## Installation
    gem install bodhi-slam

or add the following to your Gemfile:

    gem 'bodhi-slam'

## Basic Usage
### Setup
    require 'bodhi-slam'
    context = Bodhi::Context.new(server: "SERVER_URL", namespace: "NAMESPACE_NAME", username: "USERNAME", password: "PASSWORD")
    klasses = BodhiSlam.define_resources(context)

The `BodhiSlam.define_resources` method returns an array of classes built from all `Bodhi::Type` records in the namespace.
These classes will also be defined globally as constants named after their `Bodhi::Type.name` property.

    Example:
    Given a single type named "Store" is present in a namespace
    And a context is defined
    
    BodhiSlam.define_resources(context).first #=> Store

If you only need a small subset of the Resources in a namespace, you can filter using the `:include` or `:except` options

    BodhiSlam.define_resources(context, include: ["Store", "SalesTransaction"]) #only returns Store and SalesTransaction classes
    BodhiSlam.define_resources(context, except: ["Store"])                      #returns all Resources classes except Store
    
    # Symbols can also be used for the type names
    BodhiSlam.define_resources(context, except: [:Foo, :Bar])

TODO: define resources by `Bodhi::Type.package` name.

### Bodhi::Context


**All requests to the Bodhi API must be done using a `Bodhi::Context` object.**

    options = { server: "SERVER_URL", namespace: "NAMESPACE_NAME", username: "NAME", password: "PASSWORD" }
    context = Bodhi::Context.new(options)

Additionally, a `Bodhi::Context` can be initialized to use `COOKIE_AUTH` with the following options:

    options = { server: "SERVER_URL", namespace: "NAMESPACE_NAME", username: "NAME", cookie: "COOKIE" }
    context = Bodhi::Context.new(options)

**TIP: It's best to use COOKIE_AUTH whenever possible for performance reasons**

If you plan to re-use the same context, then you can set it globally by using:

    Bodhi::Context.global_context = context
    Bodhi::Context.global_context #=> returns the current global context

**Warning: Using the global context is not thread safe!  Beware of race conditions!**
#### Context Validations

    context = Bodhi::Context.new
    context.valid?      #=> false
    context.errors.any? #=> true
    context.errors.to_a #=> ["server is required", "namespace is required"]

### Types
The `Bodhi::Type` class provides an interface for interacting with data collections in the Bodhi API.  The code snippet below demonstrates how to create a new `Bodhi::Type`

    # Define a new type and save it to the cloud
    options = { bodhi_context: context, name: "TestName", properties: { foo: { type: "String" }, bar: { type: "String" } } }
    type = Bodhi::Type.new(options)
    type.save
    
    # Create the Ruby class based on the type
    # This allows all the helper functions associated Bodhi::Resource to work
    Bodhi::Type.create_class_with(type)

All `Bodhi::Type` objects inherit the following interface:

    # Class methods
    Bodhi::Type.find_all
    Bodhi::Type.find(type_name)
    Bodhi::Type.create_class_with(type)
    
    # Instance methods
    type = Bodhi::Type.new(bodhi_context: context)
    type.save
    type.delete
    type.patch(op: "replace", path: "/properties/name/type", value: "DateTime")

### Resources
All resources inherit the following interface.

    # Class methods
    Resource.all
    Resource.count
    Resource.find(sys_id)
    Resource.where(query)
    Resource.aggregate(pipeline)
    Resource.save_batch(records_array)
    Resource.delete_all
    
    # Instance methods
    record = Resource.new(bodhi_context: context)
    record.attributes #=> returns a Hash of the resource's properties and their current values
    record.save       #=> saves the resource to the cloud
    record.delete     #=> deletes the resource from the cloud
    record.update(attributes) #=> updates the resource with the given attributes
    record.patch(op: "replace", path: "/display_name", value: "test")
    
    record.persisted?  #=> false
    record.new_record? #=> true

#### Validations
    record = Resource.new
    record.valid?      #=> false
    record.errors.any? #=> true
    record.errors.to_a #=> ["name is required", "store_number can not be blank"]

#### Factories
All `Bodhi::Resource` classes have pre-defined factories based on the parent `Bodhi::Type`.  The factory will be built using the defined properties and validations from the `Bodhi::Type`.  The following methods are available for factories:

    Resource.factory.build(options)            #=> returns a randomly generated record
    Resource.factory.create(options)           #=> returns a randomly generated record and saves to the cloud
    Resource.factory.build_list(qty, options)  #=> returns an array of randomly generated records
    Resource.factory.create_list(qty, options) #=> returns an array of randomly generated records and saves each to the cloud

If you want to set a non-random property, simply add that property and value to the options hash.
All other properties will still be randomly generated.

    Resource.factory.build(name: "test", some_number: 12345)

**NOTE:  When generating a list of random records, any property set in the options hash will be applied to ALL records in the list**

##### Defining custom factory generators
If you need to define your own generators for a factory, you can access them through:

    #Get all factory generators for a resource
    Resource.factory.generators
    
    #Get a generator by its name
    Resource.factory.generators[:property]
    
    #Override an existing generator. (value must be a Lambda!)
    Resource.factory.generators[:property] = lambda { #define your generator here }

#### Query Interface
Basic query structure:

    # How to invoke a query
    Resource.where(name: "test").from(context).all    #=> returns an array of all records that match the query
    Resource.where(name: "test").from(context).first  #=> returns the first record that matches the query
    Resource.where(name: "test").from(context).last   #=> returns the last record that matches the query
    Resource.where(name: "test").from(context).count  #=> returns a count of all records that match the query
    Resource.where(name: "test").from(context).delete #=> deletes all records that match the query
    
    # Troubleshooting query issues?  Use this:
    Resource.where(name: "test").from(context).url    #=> returns a String of the URL that will be used for the query

Additional methods:

    Resource.where(query).and(other_query)                  # chains criteria for complex queries
    Resource.where(query).select("field1, field2, field3")  # filters the response to the given fields
    Resource.where(query).sort(field_name, order)           # sorts the query by the given field and sort order
    Resource.where(query).page(page_number)                 # jumps to the given page of the query
    Resource.where(query).limit(size)                       # limits the ammount of records returned by the query (must be less than 100)

Complex query criteria:

    Resource.where(foo: "12345", test: { "$exists" => true }).and(bar: { "$in" => [1,2,3] })  #=> "/resources/TestResource?where={\"foo\":\"12345\",\"test\":{\"$exists\":true},\"bar\":{\"$in\":[1,2,3]}}"

#### Aggregation Interface
The Bodhi API uses the MongoDB Aggregation Framework.  See the [MongoDB Aggregation](https://docs.mongodb.org/manual/aggregation/) page for more info on how to format your aggregation pipelines.

    pipeline = { "$match" => { name: "My Awesome Thing" } }.to_json
    Resource.aggregate(pipeline) #=> returns a Ruby Hash of the JSON response from the cloud

#### Relations

    Supported relation types:
    
    Resource.belongs_to(association_name, options={})               # Links the resource to it's parent
    Resource.has_one(association_name, options={})                  # One - One relation
    Resource.has_many(association_name, options={})                 # One - Many relation
    Resource.has_many_ids(association_name, options={})             # One - Many relation (using an array of id's)
    Resource.has_many_through(association_name, options={})         # Many - Many relation
    Resource.has_and_belongs_to_many(association_name, options={})  # Many - Many relation

Relation options:

    class_name      # defines the Resource class name if the :association_name does not match the classes name
    foreign_key     # defines a property to be used as a foreign_key on the related Resource
    primary_key     # defines a property to use as the priary key on the Resource
    query           # defines additional query criteria to use to filter related Resources

Example relations:

    # Given the Resources:
    @pokeball = Object.const_set("Pokeball", Class.new{ include Bodhi::Associations })
    @trainer = Object.const_set("Trainer", Class.new{ include Bodhi::Associations })
    @pokedex = Object.const_set("Pokedex", Class.new{ include Bodhi::Associations })
    @pokemon = Object.const_set("Pokemon", Class.new{ include Bodhi::Associations })
    
    # Using One-One
    @trainer.has_one :starter_pokemon, class_name: "Pokemon", primary_key: "name", foreign_key: "trainer_name"
    
    # Using One-Many
    @trainer.has_many :fire_pokemon, class_name: "Pokemon", primary_key: "name", foreign_key: "trainer_name", query: { type: "Fire" }
    @trainer.has_many :pokemon, through: "Pokeball"
    
    # Using One-One Through
    @trainer.has_one :pokemon, through: "Pokedex"
    @pokedex.property :trainer_id, type: "String", is_not_blank: true
    @pokemon.property :pokedex_id, type: "String", is_not_blank: true

#### Batch Uploads

**WARNING:  This is depreciated and will be removed.  DO NOT USE**

This feature utilizes MongoDB batch uploads for increased performance when inserting lots of records.  The `Resource.save_batch` method returns a `Bodhi::ResourceBatch` object, which contains the failed and created records.

    records = Resource.factory.build_list(5000, bodhi_context: context)
    batch = Resource.save_batch(records)
    batch.created #=> returns an array of all recrods that were saved
    batch.failed  #=> returns an array of all recrods that failed to save


### Simulation Helpers

#### Simulator

    # Define the settings for your simulation loop
    settings = {starts_at: "2016-06-14", iterations: 10, time_units: "days", time_scale: 1}
    settings = {starts_at: "2016-06-14", iterations: 10, time_units: "minutes", time_scale: 15}
    
    # Run the simulation
    Bodhi::Simulator.execute(settings) do |frame|
      # define your own simulation logic here
    end
    
    # Simulation Frames
    frame.iteration # the current iteration of the simulation (Integer)
    frame.time      # the current time of the simulation (DateTime)
    
    # Nesting simulations
    Bodhi::Simulator.execute(outer_settings) do |outer_frame|
      # define your own simulation logic here
      
      # run a nested simulation
      Bodhi::Simulator.execute(inner_settings) do |inner_frame|
        # define your own simulation logic here
      end
      
      # define more simulation logic here
    end

#### Normal Distributions

    Bodhi::Simulation::NormalDistributionCurve
    Core Properties:
      mean            # Mean of the distribution
      std_dev         # Standard deviation of the distribution
      scale           # The weight of the curve against others in the distribution
      
    Additional Properties:
      mean_range      # Array used to define a range that a random mean can be chosen from
      std_dev_range   # Array used to define a range that a random std_dev can be chosen from
      title           # optional title for tracking purposes
    
    Example:
      curve = { mean_range: [4.5,5.5], std_dev_range: [1, 2], scale: 1.0 }
      curve = { mean: 0, std_dev: 1, scale: 1.0 }
      
    Bodhi::Simulation::NormalDistribution
    Required Properties:
      curves          # Array of Bodhi::Simulation::NormalDistributionCurve objects
      
    Example:
      Bodhi::Simulation::NormalDistribution.new(curves: [{ mean: 0, std_dev: 1, scale: 1.0 }])

NormalDistributions can be randomized using the `mean_range` and `std_dev_range` properties of a NormalDistributionCurve object

    randomized_distribution = Bodhi::Simulation::NormalDistribution.randomize([{ mean_range: [4.5,5.5], std_dev_range: [1, 2], scale: 1.0 }])

Calculating the value at a given `x` coordinate:

    distribution = Bodhi::Simulation::NormalDistribution.new(curves: [{ mean: 0, std_dev: 1, scale: 1.0 }])
    distribution.calculate(0).round(3) #=> 0.399