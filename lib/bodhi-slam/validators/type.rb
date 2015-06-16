module Bodhi
  class TypeValidator < Validator
    attr_reader :type, :reference

    def initialize(type, reference=nil)
      if type.nil?
        raise ArgumentError.new("Expected :type to not be nil")
      end

      @type = type
      @reference = reference
    end

    def validate(record, attribute, value)
      unless value.nil?
        klass = Object.const_get(@type)
        if value.is_a?(Array)
          unless value.empty?
            record.errors.add(attribute, "must contain only #{@type}s") unless value.delete_if{ |v| v.is_a? klass }.empty?
          end
        else
          record.errors.add(attribute, "must be a #{@type}") unless value.is_a? klass
        end
        
      end
    end

    def to_options
      if @reference.nil?
        {self.to_sym => @type}
      else
        {self.to_sym => @type, ref: @reference}
      end
    end
  end
end