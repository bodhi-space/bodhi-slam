module Bodhi
  class TypeIndex
    include Bodhi::Properties
    include Bodhi::Validations

    property :keys, :options

    validates :keys, required: true, multi: true, type: "String"
    validates :options, type: "Object"
  end
end