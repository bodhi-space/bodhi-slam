module Bodhi
  class TypeValidator < Validator
    attr_reader :value, :reference

    def initialize(value, reference=nil)
      @value = value
      @reference = reference
    end
  end
end