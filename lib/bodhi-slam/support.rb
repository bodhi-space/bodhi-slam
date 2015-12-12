module Bodhi
  class Support
    def self.underscore(string)
      string.gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr("-", "_").
      downcase
    end

    def self.uncapitalize(string)
      string[0, 1].downcase + string[1..-1]
    end

    def self.camelize(string)
      underscore(string).split('_').collect(&:capitalize).join
    end

    def self.reverse_camelize(string)
      result = underscore(string).split('_').collect(&:capitalize).join
      uncapitalize(result)
    end

    def self.symbolize_keys(hash)
      hash.reduce({}) do |memo, (k, v)|
        value = v.is_a?(Hash) ? symbolize_keys(v) : v
        value = value.is_a?(Array) && value.first.is_a?(Hash) ? value.map{|item| symbolize_keys(item) } : value
        memo.merge({ k.to_sym => value })
      end
    end

    def self.coerce(value, options)
      options = symbolize_keys(options)
      case options[:type].to_s
      when "String"
        if options[:multi] == true
          value.map(&:to_s)
        else
          value.to_s
        end
      when "Real"
        if options[:multi] == true
          value.map(&:to_f)
        else
          value.to_f
        end
      when "Integer"
        if options[:multi] == true
          value.map(&:to_i)
        else
          value.to_i
        end
      when "DateTime"
        if options[:multi] == true
          value.map{|item| Time.parse(item.to_s) }
        else
          Time.parse(value.to_s)
        end
      else
        if Object.const_defined?(options[:type].to_s) && Object.const_get(options[:type].to_s).ancestors.include?(Bodhi::Properties)
          klass = Object.const_get(options[:type].to_s)
          if options[:multi] == true
            value.map{|item| klass.new(item) }
          else
            klass.new(value)
          end
        else
          value
        end
      end
    end
  end
end