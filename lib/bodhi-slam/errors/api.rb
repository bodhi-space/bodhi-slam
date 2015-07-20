module Bodhi
  class ApiErrors < StandardError
    attr_reader :body, :status

    def initialize(params={})
      @body = params[:body]
      @status = params[:status]
    end
  end
end