module Bodhi
  module Associations
    module ClassMethods
      def associations; @associations; end

      def has_one(association_name, options={})
        options = Bodhi::Support.symbolize_keys(options)
        define_association(:has_one, association_name, options)

        # Define a new helper method to get the association
        define_method(association_name) do

          # Get the value from the instance object's source_key. Default is :sys_id
          association = self.class.associations[association_name.to_sym]

          if association[:through]
            associated_object = self.send(association[:through])
            associated_object.send(association_name.to_sym)
          else
            instance_id = self.send(association[:primary_key])

            query = Bodhi::Query.new(association[:class_name]).from(self.bodhi_context).where(association[:query])
            query.and(association[:foreign_key].to_sym => instance_id)

            puts query.url
            query.first
          end
        end
      end

      def has_many(association_name, options={})
        options = Bodhi::Support.symbolize_keys(options)
        define_association(:has_many, association_name, options)

        # Define a new helper method to get the association
        define_method(association_name) do

          # Get the value from the instance object's source_key. Default is :sys_id
          association = self.class.associations[association_name.to_sym]
          instance_id = self.send(association[:primary_key])

          # Define & call the query.  Returns an Array of Objects or nil
          query = Bodhi::Query.new(association[:class_name]).from(self.bodhi_context).where(association[:query]).and(association[:foreign_key].to_sym => instance_id)
          puts query.url
          query.all
        end
      end

      def belongs_to(association_name, options={})
        options = Bodhi::Support.symbolize_keys(options)
        define_association(:belongs_to, association_name, options)

        # Define a new helper method to get the association
        define_method(association_name) do

          # Get the value from the instance object's source_key. Default is :sys_id
          association = self.class.associations[association_name.to_sym]
          instance_id = self.send(association[:primary_key])

          # Define & call the query.  Returns a single Object or nil
          query = Bodhi::Query.new(association[:class_name]).from(self.bodhi_context).where(association[:query]).and(association[:foreign_key].to_sym => instance_id)
          puts query.url
          query.first
        end
      end

      private
      def define_association(type, name, options)
        options.merge!(association_type: type)

        if options[:class_name].nil?
          options[:class_name] = Bodhi::Support.camelize(name.to_s)
        end

        case type
        when :belongs_to
          if options[:foreign_key].nil?
            options[:foreign_key] = "sys_id"
          end

          if options[:primary_key].nil?
            options[:primary_key] = Bodhi::Support.underscore(options[:class_name])+"_id"
          end
        else
          if options[:foreign_key].nil?
            options[:foreign_key] = Bodhi::Support.underscore(self.name)+"_id"
          end

          if options[:primary_key].nil?
            options[:primary_key] = "sys_id"
          end
        end

        options[:query].nil? ? options[:query] = Hash.new : options[:query]
        options[:query].merge!(options[:foreign_key].to_sym => "object.#{options[:primary_key]}")

        @associations[name.to_sym] = options
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
      base.instance_variable_set(:@associations, Hash.new)
    end
  end
end