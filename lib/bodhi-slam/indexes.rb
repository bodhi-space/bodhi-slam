module Bodhi
  module Indexes
    module ClassMethods
      def indexes; @indexes; end
      def index(keys, options={})
        # symbolize the option keys
        options = options.reduce({}) do |memo, (k, v)| 
          memo.merge({ k.to_sym => v})
        end

        @indexes << Bodhi::TypeIndex.new(keys: keys.map(&:to_s), options: options)
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
      base.instance_variable_set(:@indexes, Array.new)
    end
  end
end