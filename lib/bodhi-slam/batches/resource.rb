module Bodhi
  class ResourceBatch < Batch
    include Bodhi::Validations

    attr_accessor :type

    validates :type, type: "String", required: true, is_not_blank: true
    validates :records, type: "Bodhi::Resource", required: true, multi: true

    def initialize(type, resources=[])
      super(resources)
      @type = type
    end

    # Saves all records in the batch to the cloud
    # and populates the +created+ and +failed+ arrays with the results
    def save!(context)
      if context.invalid?
        raise Bodhi::ContextErrors.new(context.errors.messages), context.errors.to_a.to_s
      end

      records.each{ |record| record.validate! }

      response = context.connection.post do |request|
        request.url "/#{context.namespace}/resources/#{type}"
        request.headers['Content-Type'] = 'application/json'
        request.headers[context.credentials_header] = context.credentials
        request.body = records.to_json
      end

      if response.status != 200
        raise Bodhi::ApiErrors.new(body: response.body, status: response.status), "status: #{response.status}, body: #{response.body}"
      end

      # Parse the result body and update records with their sys_id
      response_body = JSON.parse(response.body)
      results = response_body.zip(records)
      results.each do |response, record|
        if response["location"]
          record.sys_id = response["location"].match(/(?<id>[a-zA-Z0-9]{24})/)[:id]
          @created.push record
        else
          @failed.push record
        end
      end

    end
  end
end