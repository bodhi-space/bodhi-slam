module Bodhi
  class Profile
    include Bodhi::Factories
    include Bodhi::Properties
    include Bodhi::Validations

    attr_accessor :bodhi_context

    property :dml,        type: "Object"
    property :name,       type: "String"
    property :namespace,  type: "String"
    property :subspace,   type: "String"
    property :parent,     type: "String"

    validates :name, type: "String", required: true, is_not_blank: true
    validates :namespace, type: "String", required: true
    validates :dml, type: "Object", required: true

    generates :name, type: "String", required: true, is_not_blank: true
    generates :namespace, type: "String", required: true
    generates :dml, type: "Object", required: true

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

  end
end