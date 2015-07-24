module Bodhi
  class User
    include Bodhi::Validations

    ATTRIBUTES = [:username, :password, :profiles, :email, :firstName, :lastName, :phone]
    attr_accessor *ATTRIBUTES
    attr_accessor :bodhi_context

    validates :username, type: "String", required: true, is_not_blank: true
    validates :password, type: "String", required: true, is_not_blank: true
    validates :profiles, type: "String", required: true, multi: true
    validates :email, type: "String", is_email: true
    validates :firstName, type: "String"
    validates :lastName, type: "String"
    validates :phone, type: "String"

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
        request.url "/#{bodhi_context.namespace}/users"
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
        request.url "/#{bodhi_context.namespace}/users/#{username}"
        request.headers[bodhi_context.credentials_header] = bodhi_context.credentials
      end

      if result.status != 204
        raise Bodhi::ApiErrors.new(body: result.body, status: result.status), "status: #{result.status}, body: #{result.body}"
      end
    end

    # Returns a factory for the Bodhi::User class
    def self.factory
      @factory ||= Bodhi::Factory.new(Bodhi::User).tap do |factory|
        factory.add_generator(:username, type: "String", required: true, is_not_blank: true)
        factory.add_generator(:password, type: "String", required: true, is_not_blank: true)
        factory.add_generator(:profiles, type: "String", required: true, multi: true)
        factory.add_generator(:email, type: "String", is_email: true)
        factory.add_generator(:firstName, type: "String")
        factory.add_generator(:lastName, type: "String")
        factory.add_generator(:phone, type: "String")
      end
    end
  end
end