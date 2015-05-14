class BodhiContext
  attr_reader :connection, :server, :namespace, 
    :credentials, :credentials_type, :credentials_header

  def initialize(params)
    params.symbolize_keys!
    
    @connection = Faraday.new(url: params[:server]) do |faraday|
      faraday.request  :url_encoded             # form-encode POST params
      #faraday.response :logger                  # log requests to STDOUT
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
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
      attributes[attribute_name] = send(attribute_name) unless [:connection, :credentials_header].include?(attribute_name)
    end
    attributes
  end
  
  def validate!
    raise ArgumentError, "Server URL must be a String" unless server.is_a?(String)
    raise ArgumentError, "Namespace name must be a String" unless namespace.is_a?(String)
  end
end