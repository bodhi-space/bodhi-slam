module Bodhi
  class ApiErrors < StandardError
    attr_reader :body, :status

    def initialize(params={})
      @body = params[:body]
      @status = params[:status]
    end

    def to_json
      { status: @status, body: @body }.to_json
    end
    alias :to_s :to_json
  end
end