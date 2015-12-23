module Bodhi
  module Associations
    module ClassMethods
      def associations; @associations; end

      def has_one(association_name, options={})
        options = Bodhi::Support.symbolize_keys(options)

        if options[:resource_name].nil?
          options[:resource_name] = Bodhi::Support.camelize(association_name.to_s)
        end

        if options[:foreign_key].nil?
          options[:foreign_key] = Bodhi::Support.underscore(name)+"_id"
        end

        if options[:source_key].nil?
          options[:source_key] = "sys_id"
        end

        options[:query].nil? ? options[:query] = Hash.new : options[:query]
        options[:query].merge!(options[:foreign_key].to_sym => "object.#{options[:source_key]}")

        @associations[:has_one][association_name.to_sym] = options
        define_method(association_name){ Bodhi::Query.new(options[:resource_name]).from(self.bodhi_context).where(options[:query]).first }
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
      base.instance_variable_set(:@associations, Hash.new(has_one:{}, has_many:{}, belongs_to:{}))
    end
  end
end