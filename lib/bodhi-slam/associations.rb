module Bodhi
  module Associations
    module ClassMethods
      def associations; @associations; end

      def has_one(association_name, options={})
        options = Bodhi::Support.symbolize_keys(options)
        define_association(:has_one, association_name, options)

        # Define a new helper method to get the association
        define_method(association_name) do
          association = self.class.associations[association_name.to_sym]
          query = Bodhi::Query.new(association[:class_name]).from(self.bodhi_context)

          if association[:through]
            through_query = Bodhi::Query.new(association[:through][:class_name]).from(self.bodhi_context)
            through_query.where(association[:through][:foreign_key].to_sym => self.send(association[:primary_key]))
            through_query.select(association[:through][:primary_key])

            puts through_query.url

            instance_id = through_query.first.send(association[:through][:primary_key])
            query.where(association[:foreign_key].to_sym => instance_id)
          else
            instance_id = self.send(association[:primary_key])
            query.where(association[:foreign_key].to_sym => instance_id)
          end

          query.and(association[:query])

          puts query.url

          query.first
        end
      end

      def has_many(association_name, options={})
        options = Bodhi::Support.symbolize_keys(options)
        define_association(:has_many, association_name, options)

        # Define a new helper method to get the association
        define_method(association_name) do

          # Get the value from the instance object's source_key. Default is :sys_id
          association = self.class.associations[association_name.to_sym]
          query = Bodhi::Query.new(association[:class_name]).from(self.bodhi_context)

          if association[:through]
            through_query = Bodhi::Query.new(association[:through][:class_name]).from(self.bodhi_context)
            through_query.where(association[:through][:foreign_key].to_sym => self.send(association[:primary_key]))
            through_query.select(association[:through][:primary_key])

            puts through_query.url

            method_chain = association[:through][:primary_key].split('.')
            if method_chain.size == 1
              instance_ids = through_query.all.map{ |item| item.send(association[:through][:primary_key]) }
            else
              instance_ids = through_query.all.map do |item|
                method_chain.reduce(item){ |memo, method| memo.send(method) }
              end
            end

            query.where(association[:foreign_key].to_sym => { "$in" => instance_ids })
          else
            instance_id = self.send(association[:primary_key])
            if instance_id.is_a?(Array)
              query.where(association[:foreign_key].to_sym => { "$in" => instance_id })
            else
              query.where(association[:foreign_key].to_sym => instance_id)
            end
          end

          query.and(association[:query])
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
          query = Bodhi::Query.new(association[:class_name]).from(self.bodhi_context)
          query.where(association[:foreign_key].to_sym => instance_id)
          query.and(association[:query])

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

        if options[:through].is_a?(String)
          case options[:association_type]
          when :has_one
            options[:through] = {
              class_name: Bodhi::Support.camelize(options[:through]),
              foreign_key: Bodhi::Support.underscore(self.name)+"_id",
              primary_key: "sys_id"
            }
            options[:foreign_key] = Bodhi::Support.underscore(options[:through][:class_name])+"_id"
          when :has_many
            options[:through] = {
              class_name: Bodhi::Support.camelize(options[:through]),
              foreign_key: Bodhi::Support.underscore(self.name)+"_id",
              primary_key: Bodhi::Support.underscore(options[:class_name])+"_id"
            }
            options[:foreign_key] = "sys_id"
          end
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
        @associations[name.to_sym] = options
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
      base.instance_variable_set(:@associations, Hash.new)
    end
  end
end