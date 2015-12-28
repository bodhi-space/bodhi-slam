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

        # Add the association to the classes :has_one association Hash
        @associations[:has_one][association_name.to_sym] = options

        # Define a new helper method to get the association
        define_method(association_name) do

          # Get the value from the instance object's source_key. Default is :sys_id
          association = self.class.associations[:has_one][association_name.to_sym]
          instance_id = self.send(association[:source_key])

          # Define & call the query.  Returns a single Object or nil
          query = Bodhi::Query.new(association[:resource_name]).from(self.bodhi_context).where(association[:query]).and(association[:foreign_key].to_sym => instance_id)
          puts query.url
          query.first
        end
      end

      def has_many(association_name, options={})
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

        # Add the association to the classes :has_one association Hash
        @associations[:has_one][association_name.to_sym] = options

        # Define a new helper method to get the association
        define_method(association_name) do

          # Get the value from the instance object's source_key. Default is :sys_id
          association = self.class.associations[:has_one][association_name.to_sym]
          instance_id = self.send(association[:source_key])

          # Define & call the query.  Returns an Array of Objects or nil
          query = Bodhi::Query.new(association[:resource_name]).from(self.bodhi_context).where(association[:query]).and(association[:foreign_key].to_sym => instance_id)
          puts query.url
          query.all
        end
      end

      def belongs_to(association_name, options={})
        options = Bodhi::Support.symbolize_keys(options)

        if options[:resource_name].nil?
          options[:resource_name] = Bodhi::Support.camelize(association_name.to_s)
        end

        if options[:foreign_key].nil?
          options[:foreign_key] = "sys_id"
        end

        if options[:source_key].nil?
          options[:source_key] = Bodhi::Support.underscore(options[:resource_name])+"_id"
        end

        options[:query].nil? ? options[:query] = Hash.new : options[:query]
        options[:query].merge!(options[:foreign_key].to_sym => "object.#{options[:source_key]}")

        # Add the association to the classes :has_one association Hash
        @associations[:has_one][association_name.to_sym] = options

        # Define a new helper method to get the association
        define_method(association_name) do

          # Get the value from the instance object's source_key. Default is :sys_id
          association = self.class.associations[:has_one][association_name.to_sym]
          instance_id = self.send(association[:source_key])

          # Define & call the query.  Returns a single Object or nil
          query = Bodhi::Query.new(association[:resource_name]).from(self.bodhi_context).where(association[:query]).and(association[:foreign_key].to_sym => instance_id)
          puts query.url
          query.first
        end
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
      base.instance_variable_set(:@associations, Hash.new(has_one:{}, has_many:{}, belongs_to:{}))
    end
  end
end