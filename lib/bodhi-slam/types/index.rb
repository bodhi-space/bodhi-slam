module Bodhi
  class TypeIndex
    include Bodhi::Properties
    include Bodhi::Validations

    property :keys, type: "String", multi: true, required: true
    property :options, type: "Object"

    validates :keys, required: true, multi: true, type: "String"
    validates :options, type: "Object"
  end
end