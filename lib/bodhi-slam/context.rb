require 'bodhi-slam/validations'

module Bodhi
  class Context
    include Bodhi::Validations
    attr_reader :connection, :server, :namespace, :credentials, :credentials_type, :credentials_header

    validates :server, required: true, is_not_blank: true, url: true
    validates :namespace, required: true, is_not_blank: true

    def self.global_context
      @@current_context ||= Bodhi::Context.new
    end

    def self.global_context=(context)
      @@current_context = context
    end

    def initialize(params)
      @connection = Faraday.new(url: params[:server]) do |faraday|
        faraday.request :multipart
        faraday.request :url_encoded

        faraday.adapter :net_http_persistent
        #faraday.adapter  Faraday.default_adapter

        faraday.response :json, :content_type => /\bjson$/
        #faraday.response :logger
      end
      @server = params[:server]
      @namespace = params[:namespace]
    
      if params[:cookie]
        @credentials = params[:cookie]
        @credentials_header = "Cookie"
        @credentials_type = "HTTP_COOKIE"
      else
        @credentials = @connection.basic_auth params[:username], params[:password]
        @credentials_header = "Authorization"
        @credentials_type = "HTTP_BASIC"
      end
    end
  
    def attributes
      attributes = Hash.new
      self.instance_variables.each do |variable|
        attribute_name = variable.to_s.delete('@').to_sym
        attributes[attribute_name] = send(attribute_name)
      end
      attributes
    end

  end
end