module Bodhi
  class Profile
    include Bodhi::Validations

    ATTRIBUTES = [:name, :namespace, :dml, :subspace, :parent]
    attr_accessor *ATTRIBUTES
    attr_accessor :bodhi_context

    validates :name, type: "String", required: true, is_not_blank: true
    validates :namespace, type: "String", required: true
    validates :dml, type: "Object", required: true

    def initialize(params={})
      # same as symbolize_keys!
      params = params.reduce({}) do |memo, (k, v)| 
        memo.merge({ k.to_sym => v})
      end

      # set attributes
      ATTRIBUTES.each do |attribute|
        send("#{attribute}=", params[attribute])
      end
    end

    # Returns a Hash of the Objects form attributes
    # 
    #   s = SomeResource.factory.build({foo:"test", bar:12345})
    #   s.attributes # => { foo: "test", bar: 12345 }
    def attributes
      result = Hash.new
      ATTRIBUTES.each do |attribute|
        result[attribute] = send(attribute)
      end
      result
    end

    # Returns all the Objects attributes as JSON.
    # It converts any nested Objects to JSON if they respond to +to_json+
    # 
    #   s = SomeResource.factory.build({foo:"test", bar:12345})
    #   s.to_json # => "{ 'foo':'test', 'bar':12345 }"
    def to_json(base=nil)
      super if base
      attributes.to_json
    end

    # Saves the resource to the Bodhi Cloud.  Raises ArgumentError if record could not be saved.
    # 
    #   obj = Resouce.new
    #   obj.save!
    #   obj.persisted? # => true
    def save!
      result = bodhi_context.connection.post do |request|
        request.url "/#{bodhi_context.namespace}/profiles"
        request.headers['Content-Type'] = 'application/json'
        request.headers[bodhi_context.credentials_header] = bodhi_context.credentials
        request.body = attributes.to_json
      end

      if result.status != 201
        raise Bodhi::ApiErrors.new(body: result.body, status: result.status), "status: #{result.status}, body: #{result.body}"
      end
    end

    def delete!
      result = bodhi_context.connection.delete do |request|
        request.url "/#{bodhi_context.namespace}/profiles/#{name}"
        request.headers[bodhi_context.credentials_header] = bodhi_context.credentials
      end

      if result.status != 204
        raise Bodhi::ApiErrors.new(body: result.body, status: result.status), "status: #{result.status}, body: #{result.body}"
      end
    end

    # Returns a factory for the Bodhi::User class
    def self.factory
      @factory ||= Bodhi::Factory.new(Bodhi::Profile).tap do |factory|
        factory.add_generator(:name, type: "String", required: true, is_not_blank: true)
        factory.add_generator(:namespace, type: "String", required: true)
        factory.add_generator(:dml, type: "Object", required: true)
      end
    end

    # Queries the Bodhi API for the given +user_name+ and
    # returns a Bodhi::Profile
    # 
    #   context = BodhiContext.new(valid_params)
    #   profile = Bodhi::Profile.find(context, "Profile1")
    #   profile # => #<Bodhi::Profile:0x007fbff403e808 @name="Profile1">
    def self.find(context, profile_name)
      if context.invalid?
        raise Bodhi::ContextErrors.new(context.errors.messages), context.errors.to_a.to_s
      end

      result = context.connection.get do |request|
        request.url "/#{context.namespace}/profiles/#{profile_name}"
        request.headers[context.credentials_header] = context.credentials
      end

      if result.status != 200
        raise Bodhi::ApiErrors.new(body: result.body, status: result.status), "status: #{result.status}, body: #{result.body}"
      end

      profile = Bodhi::Profile.new(result.body)
      profile.bodhi_context = context
      profile
    end
  end
end