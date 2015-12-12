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
  end
end