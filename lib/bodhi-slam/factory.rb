module Bodhi
  module Factories
    module ClassMethods
      # Returns the Classes +Bodhi::Factory+ object
      # @return [Bodhi::Factory]
      def factory; @factory; end

      # Define a factory generator with the given +name+ and +options+
      # and append to the Classes Bodhi::Factory
      # @param name [String] the name of the property
      # @param options [Hash] the Bodhi::Properties
      # @return [nil]
      def generates(name, options)
        @factory.add_generator(name.to_sym, options)
        return nil
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
      base.instance_variable_set(:@factory, Bodhi::Factory.new(base))
    end
  end

  # Randomize and save records to the cloud.
  #
  # Use the built in {Bodhi::Validator} classes to define constraints for
  # randomizing records.  You can also create your own lambda expressions for further
  # fine grain control.
  # @example Define factories
  #   factory = Bodhi::Factory.new(Drone)
  # @example Default generators using {Bodhi::Type.properties} options
  #   factory.add_generator(:motor_count, type: Integer, min: 1, max: 8 )
  # @example Create custom generators using lambda syntax
  #   factory.add_generator(:color, lambda { ["Red", "Green", "Blue", "Black"].sample } )
  # @example Build a new record with randomly generated attributes
  #   quad_copter = factory.build(motor_count: 4)
  #   quad_copter # => #<Drone:0x007fbff403e808 @motor_count=4 @color="Red" >
  # @example Build an array of random records
  #   quad_copters = factory.build_list(10, motor_count: 4)
  #   quad_copters # => [#<Drone:0x007fbff403e808 @motor_count=4 @color="Blue" >, ...]
  class Factory
    # The class that will be used to generate random instances
    attr_reader :klass

    # Hash of property names with lambda's to generate random values
    attr_accessor :generators

    # Initialize with base class
    def initialize(base)
      @klass = base
      @generators = Hash.new
    end

    # Builds a new randomly generated resource
    # and accepts a options hash to override specified properties.
    #
    # @param options [Hash] the properties and values that should +NOT+ be randomized
    # @return [Bodhi::Resource] the randomly generated resource
    # @example
    #   Resource.factory.build # => #<Resource:0x007fbff403e808 @name="2-3lmwp^oef@245">
    #   Resource.factory.build(name: "test") # => #<Resource:0x007fbff403e808 @name="test">
    def build(options={})
      options = Bodhi::Support.symbolize_keys(options)
      object = klass.new(options)

      @generators.each_pair do |attribute, generator|
        unless options.has_key?(attribute)
          object.send("#{attribute}=", generator.call)
        end
      end

      object
    end

    # Builds an array of randomly generated resources
    # and accepts a options hash to override specified properties.
    #
    # @param size [Integer] the amount of resources to generate
    # @param options [Hash] the properties and values that should +NOT+ be randomized
    # @return [Array<Bodhi::Resource>] An Array of randomly generated resources
    # @example
    #   Resource.factory.build_list(10) # => [#<Resource:0x007fbff403e808 @name="2-3lmwp^oef@245">, #<Resource:0x007fbff403e808 @name="p7:n#$903<u1">, ...]
    #   Resource.factory.build_list(10, name: "test") # => [#<Resource:0x007fbff403e808 @name="test">, #<Resource:0x007fbff403e808 @name="test">, ...]
    def build_list(size, options={})
      size.times.collect{ build(options) }
    end

    # Generates a random resource and saves it to the IoT Platform
    # and accepts a options hash to override specified properties.
    #
    # @param options [Hash] the properties and values that should +NOT+ be randomized
    # @return [Bodhi::Resource] the randomly generated resource
    # @example
    #   Resource.factory.create(context) # => #<Resource:0x007fbff403e808 @name="2-3lmwp^oef@245">
    #   Resource.factory.create(context, name: "test") # => #<Resource:0x007fbff403e808 @name="test">
    def create(options={})
      object = build(options)
      object.save!
      object
    end

    # Generates an array of random resources and saves them to the IoT Platform
    # and accepts a options hash to override specified properties.
    #
    # @param size [Integer] the amount of resources to generate
    # @param options [Hash] the properties and values that should +NOT+ be randomized
    # @return [Array<Bodhi::Resource>] An Array of randomly generated resources
    # @raise [Bodhi::ApiErrors] if any resource failed to be saved
    # @example
    #   Resource.factory.create_list(10, context) # => [#<Resource:0x007fbff403e808 @name="2-3lmwp^oef@245">, #<Resource:0x007fbff403e808 @name="p7:n#$903<u1">, ...]
    #   Resource.factory.create_list(10, context, name: "test") # => [#<Resource:0x007fbff403e808 @name="test">, #<Resource:0x007fbff403e808 @name="test">, ...]
    def create_list(size, options={})
      resources = build_list(size, options)
      resources.each{ |resource| resource.save! }
      resources
    end

    # Adds a new generator to the class with the specified +name+ and +options+
    #
    # @param name [String, Symbol] the name of the property
    # @param options [Hash] the Bodhi::Properties options to generate
    # @return [nil]
    # @example
    #   Resource.factory.add_generator("name", type: "String")
    #   Resource.factory.add_generator("test", type: "Integer", multi: true, required: true)
    def add_generator(name, options)
      if options.is_a?(Proc)
        @generators[name.to_sym] = options
      else
        @generators[name.to_sym] = build_default_generator(options)
      end

      return nil
    end

    private

    # @todo clean up this nasty abomination of a method!
    def build_default_generator(options)
      options = options.reduce({}) do |memo, (k, v)|
        memo.merge({ Bodhi::Support.underscore(k.to_s).to_sym => v})
      end

      case options[:type]
      when "String"
        characters = [('a'..'z'), ('A'..'Z'), ('0'..'9')].map { |i| i.to_a }.flatten
        "~!@#$%^&*()_+-=:;<>?,./ ".each_char{ |c| characters.push(c) }

        if options[:multi]
          if options[:is_not_blank]
            generator = lambda{ [*0..5].sample.times.collect{ [*1..100].sample.times.map{ characters[rand(characters.length)] }.join } }
          elsif options[:is_email]
            generator = lambda{ [*0..5].sample.times.collect{ /\p{Alnum}{5,10}@\p{Alnum}{5,10}\.\p{Alnum}{2,3}/i.random_example } }
          elsif options[:matches]
            generator = lambda do
              begin
                [*0..5].sample.times.collect{ Regexp.new(options[:matches]).random_example }
              rescue
                nil
              end
            end
          elsif options[:length]
            min = JSON.parse(options[:length]).first
            max = JSON.parse(options[:length]).last
            generator = lambda{ [*0..5].sample.times.collect{ [*min..max].sample.times.map{ characters[rand(characters.length)] }.join } }
          else
            generator = lambda{ [*0..5].sample.times.collect{ [*0..100].sample.times.map{ characters[rand(characters.length)] }.join } }
          end
        else
          if options[:is_not_blank]
            generator = lambda{ [*1..100].sample.times.map{ characters[rand(characters.length)] }.join }
          elsif options[:is_email]
            generator = lambda{ /\p{Alnum}{5,10}@\p{Alnum}{5,10}\.\p{Alnum}{2,3}/i.random_example }
          elsif options[:matches]
            generator = lambda do
              begin
                Regexp.new(options[:matches]).random_example
              rescue
                nil
              end
            end
          elsif options[:length]
            min = JSON.parse(options[:length]).first
            max = JSON.parse(options[:length]).last
            generator = lambda{ [*min..max].sample.times.map{ characters[rand(characters.length)] }.join }
          else
            generator = lambda{ [*0..100].sample.times.map{ characters[rand(characters.length)] }.join }
          end
        end

      when "DateTime"
        if options[:multi]
          generator = lambda { [*0..5].sample.times.collect{ Time.at(rand * Time.now.to_i) } }
        else
          generator = lambda { Time.at(rand * Time.now.to_i) }
        end

      when "Integer"
        options[:min].nil? ? min = -2147483647 : min = options[:min]
        options[:max].nil? ? max = 2147483647 : max = options[:max]

        if options[:multi]
          generator = lambda { [*0..5].sample.times.collect{ rand(min..max) } }
        else
          generator = lambda { rand(min..max) }
        end

      when "Real"
        options[:min].nil? ? min = -1483647.0 : min = options[:min]
        options[:max].nil? ? max = 1483647.0 : max = options[:max]

        if options[:multi]
          generator = lambda { [*0..5].sample.times.collect{ rand(min..max) } }
        else
          generator = lambda { rand(min..max) }
        end

      when "Boolean"
        if options[:multi]
          generator = lambda { [*0..5].sample.times.collect{ [true, false].sample } }
        else
          generator = lambda { [true, false].sample }
        end

      when "GeoJSON"
        # define the GeoJSON coordinate types
        geojson_types = ["Point", "MultiPoint", "LineString", "MultiLineString", "Polygon", "MultiPolygon"]

        # define max/min longitude
        min_long = -180.0
        max_long = 180.0

        # define max/min lattitude
        min_lat = -90.0
        max_lat = 90.0

        if options[:multi]
          generator = lambda do
            [*0..5].sample.times.collect do
              type = geojson_types.sample

              case type
              when "Point"
                coordinates = [rand(min_long..max_long), rand(min_lat..max_lat)]
              when "MultiPoint"
                coordinates = [*2..10].sample.times.collect{ [rand(min_long..max_long), rand(min_lat..max_lat)] }
              when "LineString"
                coordinates = [*2..10].sample.times.collect{ [rand(min_long..max_long), rand(min_lat..max_lat)] }
              when "MultiLineString"
                coordinates = [*2..10].sample.times.collect do
                  [*2..10].sample.times.collect{ [rand(min_long..max_long), rand(min_lat..max_lat)] }
                end
              when "Polygon"
                coordinates = [*2..10].sample.times.collect do
                  [*2..10].sample.times.collect{ [rand(min_long..max_long), rand(min_lat..max_lat)] }
                end
              when "MultiPolygon"
                coordinates = [*2..10].sample.times.collect do
                  [*2..10].sample.times.collect do
                    [*2..10].sample.times.collect{ [rand(min_long..max_long), rand(min_lat..max_lat)] }
                  end
                end
              end

              { type: type, coordinates: coordinates }
            end
          end
        else
          generator = lambda do
            type = geojson_types.sample

            case type
            when "Point"
              coordinates = [rand(min_long..max_long), rand(min_lat..max_lat)]
            when "MultiPoint"
              coordinates = [*2..10].sample.times.collect{ [rand(min_long..max_long), rand(min_lat..max_lat)] }
            when "LineString"
              coordinates = [*2..10].sample.times.collect{ [rand(min_long..max_long), rand(min_lat..max_lat)] }
            when "MultiLineString"
              coordinates = [*2..10].sample.times.collect do
                [*2..10].sample.times.collect{ [rand(min_long..max_long), rand(min_lat..max_lat)] }
              end
            when "Polygon"
              coordinates = [*2..10].sample.times.collect do
                [*2..10].sample.times.collect{ [rand(min_long..max_long), rand(min_lat..max_lat)] }
              end
            when "MultiPolygon"
              coordinates = [*2..10].sample.times.collect do
                [*2..10].sample.times.collect do
                  [*2..10].sample.times.collect{ [rand(min_long..max_long), rand(min_lat..max_lat)] }
                end
              end
            end

            { type: type, coordinates: coordinates }
          end
        end

      when "Object"
        if options[:multi]
          generator = lambda { [*0..5].sample.times.collect{ {SecureRandom.hex => SecureRandom.hex} } }
        else
          generator = lambda { {SecureRandom.hex => SecureRandom.hex} }
        end

      when "Link"
        if options[:multi]
          generator = lambda do
            [*0..5].sample.times.collect do
              result = Hash.new
              result[:href] = Regexp.new(/^https?:\/\/([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$/).random_example
              result[:name] = Regexp.new(/^.{10,20}$/).random_example if [true, false].sample == true
              result[:title] = Regexp.new(/^.{10,20}$/).random_example if [true, false].sample == true
              result[:templated] = [true, false].sample if [true, false].sample == true
              result[:type] = ["application/json", "text/css", "application/exe", "zip"].sample if [true, false].sample == true
              result[:deprecation] = Regexp.new(/^https?:\/\/([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$/).random_example if [true, false].sample == true
              result[:profile] = Regexp.new(/^https?:\/\/([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$/).random_example if [true, false].sample == true
              result[:hreflang] = ["en-us", "fr", "de"].sample if [true, false].sample == true
              result
            end
          end
        else
          generator = lambda do
            result = Hash.new
            result[:href] = Regexp.new(/^https?:\/\/([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$/).random_example
            result[:name] = Regexp.new(/^.{10,20}$/).random_example if [true, false].sample == true
            result[:title] = Regexp.new(/^.{10,20}$/).random_example if [true, false].sample == true
            result[:templated] = [true, false].sample if [true, false].sample == true
            result[:type] = ["application/json", "text/css", "application/exe", "zip"].sample if [true, false].sample == true
            result[:deprecation] = Regexp.new(/^https?:\/\/([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$/).random_example if [true, false].sample == true
            result[:profile] = Regexp.new(/^https?:\/\/([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$/).random_example if [true, false].sample == true
            result[:hreflang] = ["en-us", "fr", "de"].sample if [true, false].sample == true
            result
          end
        end

      when "Enumerated"
        generator = lambda do
          ref = options[:ref].split('.')
          enum_name = ref[0]
          field = ref[1]

          if Bodhi::Enumeration.cache[enum_name.to_sym].nil?
            raise RuntimeError.new("Cannot add generator for attribute: #{name}.  #{enum_name} enumeration not found")
          end

          if options[:multi]
            if field.nil?
              [*0..5].sample.times.collect{ Bodhi::Enumeration.cache[enum_name.to_sym].values.sample }
            else
              [*0..5].sample.times.collect{ Bodhi::Enumeration.cache[enum_name.to_sym].values.sample[field.to_sym] }
            end
          else
            if field.nil?
              Bodhi::Enumeration.cache[enum_name.to_sym].values.sample
            else
              Bodhi::Enumeration.cache[enum_name.to_sym].values.sample[field.to_sym]
            end
          end
        end

      else
        if options[:multi]
          generator = lambda do
            embedded_klass = Object.const_get(options[:type])

            if embedded_klass == klass
              nil
            else
              [*0..5].sample.times.collect{ embedded_klass.factory.build }
            end
          end
        else
          generator = lambda do
            embedded_klass = Object.const_get(options[:type])

            if embedded_klass == klass
              nil
            else
              embedded_klass.factory.build
            end
          end
        end
      end
    end

  end
end
