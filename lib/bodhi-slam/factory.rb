module Bodhi
  class Factory
    attr_reader :klass
    attr_accessor :generators

    def initialize(base)
      @klass = base
      @generators = Hash.new
    end

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
        if params[attribute]
          object.send("#{attribute}=", params[attribute])
        else
          object.send("#{attribute}=", generator.call)
        end
      end
      object
    end

    def build_list(size, *args)
      size.times.collect{ build(*args) }
    end

    def create(context, params={})
      if context.invalid?
        raise context.errors
      end

      object = build(params)
      object.bodhi_context = context
      object.save!
      object
    end

    def create_list(size, context, params={})
      if context.invalid?
        raise context.errors
      end

      resources = build_list(size, params)
      result = context.connection.post do |request|
        request.url "/#{context.namespace}/resources/#{klass}"
        request.headers['Content-Type'] = 'application/json'
        request.headers[context.credentials_header] = context.credentials
        request.body = resources.to_json
      end

      #puts "\033[33mResult Body\033[0m: \033[36m#{result.body}\033[0m"

      if result.status != 200
        errors = JSON.parse result.body
        errors.each{|error| error['status'] = result.status } if errors.is_a? Array
        errors["status"] = result.status if errors.is_a? Hash
        raise errors.to_s
      end

      #puts "\033[33mRecords\033[0m: \033[36m#{records.map(&:attributes)}\033[0m"

      resources
    end

    def add_generator(name, options)
      case options[:type]
      when "String"
        characters = [('a'..'z'), ('A'..'Z'), ('0'..'9')].map { |i| i.to_a }.flatten
        "~!@#$%^&*()_+-=:;<>?,./ ".each_char{ |c| characters.push(c) }

        generator = lambda do
          if options[:multi]
            [*0..5].sample.times.collect{ [*0..50].sample.times.map{ characters[rand(characters.length)] }.join }
          else
            [*0..50].sample.times.map{ characters[rand(characters.length)] }.join
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
        if options[:multi]
          generator = lambda { [*0..5].sample.times.collect{ SecureRandom.random_number*[-1,1,1,1].sample*[10,100,1000,10000].sample } }
        else
          generator = lambda { SecureRandom.random_number*[-1,1,1,1].sample*[10,100,1000,10000].sample }
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

      when "Enumerated"
        generator = lambda do
          ref = options[:ref].split('.')
          name = ref[0]
          field = ref[1]

          if options[:multi]
            if field.nil?
              [*0..5].sample.times.collect{ Bodhi::Enumeration.cache[name.to_sym].values.sample }
            else
              [*0..5].sample.times.collect{ Bodhi::Enumeration.cache[name.to_sym].values.sample[field.to_sym] }
            end
          else
            if field.nil?
              Bodhi::Enumeration.cache[name.to_sym].values.sample
            else
              Bodhi::Enumeration.cache[name.to_sym].values.sample[field.to_sym]
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