require 'bodhi-slam/validations'

module Bodhi
  class Context
    include Bodhi::Validations
    attr_reader :connection, :server, :namespace, 
      :credentials, :credentials_type, :credentials_header
    
      validates :server, required: true, is_not_blank: true, url: true
      validates :namespace, required: true, is_not_blank: true
    
    def initialize(params)
      @connection = Faraday.new(url: params[:server]) do |faraday|
        faraday.request  :url_encoded             # form-encode POST params
        #faraday.response :logger                  # log requests to STDOUT
        #faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
        faraday.adapter :net_http_persistent
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