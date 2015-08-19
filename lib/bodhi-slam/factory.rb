module Bodhi
  class Factory
    attr_reader :klass
    attr_accessor :generators

    def initialize(base)
      @klass = base
      @generators = Hash.new
    end

    # Returns a new randomly generated resource.
    # Accepts an options hash to override specified values.
    # 
    #   Resource.factory.build # => #<Resource:0x007fbff403e808 @name="2-3lmwp^oef@245">
    #   Resource.factory.build(name: "test") # => #<Resource:0x007fbff403e808 @name="test">
    def build(*args)
      if args.last.is_a?(Hash)
        params = args.last.reduce({}) do |memo, (k, v)| 
          memo.merge({ k.to_sym => v})
        end
      else
        params = Hash.new
      end

      object = klass.new
      @generators.each_pair do |attribute, generator|
        if params.has_key?(attribute)
          object.send("#{attribute}=", params[attribute])
        else
          object.send("#{attribute}=", generator.call)
        end
      end
      object
    end

    # Returns an array of randomly generated resources
    # 
    #   Resource.factory.build_list(10) # => [#<Resource:0x007fbff403e808 @name="2-3lmwp^oef@245">, #<Resource:0x007fbff403e808 @name="p7:n#$903<u1">, ...]
    #   Resource.factory.build_list(10, name: "test") # => [#<Resource:0x007fbff403e808 @name="test">, #<Resource:0x007fbff403e808 @name="test">, ...]
    def build_list(size, *args)
      size.times.collect{ build(*args) }
    end

    # Builds and saves a new resource to the given +context+
    # Accepts an options hash to override specified values.
    # 
    #   context = Bodhi::Context.new
    #   Resource.factory.create(context) # => #<Resource:0x007fbff403e808 @name="2-3lmwp^oef@245">
    #   Resource.factory.create(context, name: "test") # => #<Resource:0x007fbff403e808 @name="test">
    def create(context, params={})
      if context.invalid?
        raise context.errors, context.errors.to_a.to_s
      end

      object = build(params)
      object.bodhi_context = context
      object.save!
      object
    end

    # Builds and saves a list of resources to the given +context+
    # Accepts an options hash to override specified values.
    # 
    #   Resource.factory.create_list(10, context) # => [#<Resource:0x007fbff403e808 @name="2-3lmwp^oef@245">, #<Resource:0x007fbff403e808 @name="p7:n#$903<u1">, ...]
    #   Resource.factory.create_list(10, context, name: "test") # => [#<Resource:0x007fbff403e808 @name="test">, #<Resource:0x007fbff403e808 @name="test">, ...]
    def create_list(size, context, params={})
      if context.invalid?
        raise context.errors, context.errors.to_a.to_s
      end

      resources = build_list(size, params)
      resources.each do |resource|
        resource.bodhi_context = context
        resource.save!
      end

      resources
    end

    # Adds a new generator to the class with the specified +name+ and +options+
    # 
    #   Resource.factory.add_generator("name", type: "String")
    #   Resource.factory.add_generator("test", type: "Integer", multi: true, required: true)
    def add_generator(name, options)
      options = options.reduce({}) do |memo, (k, v)| 
        memo.merge({ k.to_s.gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').gsub(/([a-z\d])([A-Z])/,'\1_\2').tr("-", "_").downcase.to_sym => v})
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
            generator = lambda{ [*0..5].sample.times.collect{ Regexp.new(options[:matches]).random_example } }
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
            generator = lambda{ Regexp.new(options[:matches]).random_example }
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
          generator = lambda { [*0..5].sample.times.collect{ Time.at(rand * Time.now.to_i).iso8601 } }
        else
          generator = lambda { Time.at(rand * Time.now.to_i).iso8601 }
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
        if options[:multi]
          generator = lambda { [*0..5].sample.times.collect{ {type: "Point", coordinates: [10,20]} } }
        else
          generator = lambda { {type: "Point", coordinates: [10,20]} }
        end

      when "Object"
        if options[:multi]
          generator = lambda { [*0..5].sample.times.collect{ {SecureRandom.hex => SecureRandom.hex} } }
        else
          generator = lambda { {SecureRandom.hex => SecureRandom.hex} }
        end

      when "Link"
        if options[:multi]
          generator = lambda { [*0..5].sample.times.collect{ Hash.new } }
        else
          generator = lambda { Hash.new }
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
        generator = lambda do
          embedded_klass = Object.const_get(options[:type])

          if options[:multi]
            [*0..5].sample.times.collect{ embedded_klass.factory.build }
          else
            embedded_klass.factory.build
          end
        end
      end

      @generators[name.to_sym] = generator
    end

  end
end