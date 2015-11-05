module Bodhi
  class User
    include Bodhi::Properties
    include Bodhi::Validations

    attr_accessor :bodhi_context

    property :username, :password, :profiles, :authorizations, :email, :firstName, :lastName, :phone, :usertype, :namespace

    validates :username, type: "String", required: true, is_not_blank: true
    validates :password, type: "String", required: true, is_not_blank: true
    validates :profiles, type: "String", required: true, multi: true
    validates :email, type: "String", is_email: true
    validates :firstName, type: "String"
    validates :lastName, type: "String"
    validates :phone, type: "String"

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

    # Queries the Bodhi API for the given +user_name+ and
    # returns a Bodhi::User
    # 
    #   context = BodhiContext.new(valid_params)
    #   user = Bodhi::User.find(context, "User1")
    #   user # => #<Bodhi::User:0x007fbff403e808 @username="User1">
    def self.find(context, user_name)
      if context.invalid?
        raise Bodhi::ContextErrors.new(context.errors.messages), context.errors.to_a.to_s
      end

      result = context.connection.get do |request|
        request.url "/#{context.namespace}/users/#{user_name}"
        request.headers[context.credentials_header] = context.credentials
      end

      if result.status != 200
        raise Bodhi::ApiErrors.new(body: result.body, status: result.status), "status: #{result.status}, body: #{result.body}"
      end

      user = Bodhi::User.new(result.body)
      user.bodhi_context = context
      user
    end

    # Queries the Bodhi API for the users account info
    # 
    #   context = BodhiContext.new(valid_params)
    #   user_properties = Bodhi::User.find_me(context)
    def self.find_me(context)
      if context.invalid?
        raise Bodhi::ContextErrors.new(context.errors.messages), context.errors.to_a.to_s
      end

      result = context.connection.get do |request|
        request.url "/me"
        request.headers[context.credentials_header] = context.credentials
      end

      if result.status != 200
        raise Bodhi::ApiErrors.new(body: result.body, status: result.status), "status: #{result.status}, body: #{result.body}"
      end

      result.body
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

  end
end