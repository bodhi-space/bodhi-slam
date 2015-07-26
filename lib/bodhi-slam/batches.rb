module Bodhi
  class Batch
    attr_accessor :records
    attr_reader :created, :failed

    def initialize(records=[])
      @records = records
      @created = []
      @failed = []
    end

    # Saves the batch of records to the Bodhi cloud.
    def save!(context)
      raise NotImplementedError, "Subclasses must implement a save!(context) method."
    end
  end
end

Dir[File.dirname(__FILE__) + "/batches/*.rb"].each { |file| require file }