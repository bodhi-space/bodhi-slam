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
      string.split('_').collect(&:capitalize).join
    end

    def self.reverse_camelize(string)
      result = string.split('_').collect(&:capitalize).join
      uncapitalize(result)
    end
  end
end