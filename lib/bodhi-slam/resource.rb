module BodhiResource
  SYSTEM_ATTRIBUTES = [:bodhi_context, :sys_created_at, :sys_version, :sys_modified_at, :sys_modified_by,
    :sys_namespace, :sys_created_by, :sys_type_version, :sys_id]
  attr_accessor *SYSTEM_ATTRIBUTES
  
  # - Returns a Hash of the Objects form attributes
  def attributes
    attributes = Hash.new
    self.instance_variables.each do |variable|
      attribute_name = variable.to_s.delete('@').to_sym
      attributes[attribute_name] = send(attribute_name) unless SYSTEM_ATTRIBUTES.include?(attribute_name)
    end
    attributes
  end
  
  # - Converts all the Objects attributes to JSON
  def to_json
    attributes = Hash.new
    self.instance_variables.each do |variable|
      attribute_name = variable.to_s.delete('@').to_sym
      attributes[attribute_name] = send(attribute_name)
    end
    attributes.to_json
  end

  def save!
    result = bodhi_context.connection.post do |request|
      request.url "/#{bodhi_context.namespace}/resources/#{self.class}"
      request.headers['Content-Type'] = 'application/json'
      request.headers[bodhi_context.credentials_header] = bodhi_context.credentials
      request.body = attributes.to_json
    end
  
    if result.status != 201
      errors = JSON.parse result.body
      errors.each{|error| error['status'] = result.status } if errors.is_a? Array
      errors["status"] = result.status if errors.is_a? Hash
      raise errors.to_s
    end
  
    if result.headers['location']
      @sys_id = result.headers['location'].match(/(?<id>[a-zA-Z0-9]{8}-[a-zA-Z0-9]{4}-[a-zA-Z0-9]{4}-[a-zA-Z0-9]{4}-[a-zA-Z0-9]{12})/)[:id]
    end
  end

  def delete!
    result = bodhi_context.connection.delete do |request|
      request.url "/#{bodhi_context.namespace}/resources/#{self.class}/#{sys_id}"
      request.headers[bodhi_context.credentials_header] = bodhi_context.credentials
    end
  
    if result.status != 204
      errors = JSON.parse result.body
      errors.each{|error| error['status'] = result.status } if errors.is_a? Array
      errors["status"] = result.status if errors.is_a? Hash
      raise errors.to_s
    end
  end

  def patch!(params)
    result = bodhi_context.connection.patch do |request|
      request.url "/#{bodhi_context.namespace}/resources/#{self.class}/#{sys_id}"
      request.headers['Content-Type'] = 'application/json'
      request.headers[bodhi_context.credentials_header] = bodhi_context.credentials
      request.body = params
    end
  
    if result.status != 204
      errors = JSON.parse result.body
      errors.each{|error| error['status'] = result.status } if errors.is_a? Array
      errors["status"] = result.status if errors.is_a? Hash
      raise errors.to_s
    end
  end  
end