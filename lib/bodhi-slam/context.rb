class BodhiContext
  attr_reader :errors, :connection, :server, :namespace, 
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
    
    @errors = Bodhi::Errors.new
  end
  
  def attributes
    attributes = Hash.new
    self.instance_variables.each do |variable|
      attribute_name = variable.to_s.delete('@').to_sym
      attributes[attribute_name] = send(attribute_name)
    end
    attributes
  end
  
  # - Runs all the specified validations and returns true if no errors were added otherwise false.
  def valid?
    errors.add(:server, "must be present") if server.nil?
    errors.add(:server, "must be a string") unless server.is_a? String
    
    errors.add(:namespace, "must be present") if namespace.nil?
    errors.add(:namespace, "must be a string") unless namespace.is_a? String
    
    return !errors.messages.any?
  end
  
  # - Performs the opposite of valid?. Returns true if errors were added, false otherwise.
  def invalid?
    errors.add(:server, "must be present") if server.nil?
    errors.add(:server, "must be a string") unless server.is_a? String
    
    errors.add(:namespace, "must be present") if namespace.nil?
    errors.add(:namespace, "must be a string") unless namespace.is_a? String
    
    return errors.messages.any?
  end
end