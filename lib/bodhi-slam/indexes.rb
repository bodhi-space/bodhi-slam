module Bodhi
  module Indexes
    module ClassMethods
      def indexes; @indexes; end
      def index(keys, options={})
        options = Bodhi::Support.symbolize_keys(options)
        @indexes << Bodhi::TypeIndex.new(keys: keys.map(&:to_s), options: options)
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
      base.instance_variable_set(:@indexes, Array.new)
    end
  end
end