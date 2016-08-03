class PropertiesHandler < YARD::Handlers::Ruby::Base
  handles method_call(:property)
  namespace_only

  # For reference:
  # http://yardoc.org/guides/extending-yard/writing-handlers.html

  process do
    return if statement.type == :var_ref || statement.type == :vcall
    read, write = true, true
    params = statement.parameters(false).dup

    name = statement.parameters.first.jump(:tstring_content, :ident).source
    options = statement.parameters[1].jump(:tstring_content, :ident).source
    return_type = options.gsub(/type:\s+"?([a-zA-Z0-9_:]+)"?.*/, '\1')

    # Check the options for the +multi+ param
    unless options.index(/multi:\s+true/).nil?
      return_type = "Array<#{return_type}>"
    end

    namespace.attributes[scope][name] ||= SymbolHash[:read => nil, :write => nil]

    # Show their methods as well
    {:read => name, :write => "#{name}="}.each do |type, meth|
      if (type == :read ? read : write)
        o = MethodObject.new(namespace, meth, scope)
        if type == :write
          o.parameters = [['value', nil]]
          src = "def #{meth}(value)"
          full_src = "#{src}\n  @#{name} = value\nend"
        else
          src = "def #{meth}"
          full_src = "#{src}\n  @#{name}\nend"
        end
        o.add_tag YARD::Tags::Library.new.return_tag("[#{return_type}]")
        o.source ||= full_src
        o.signature ||= src
        register(o)
        o.docstring = doc if o.docstring.blank?(false)

        # Regsiter the object explicitly
        namespace.attributes[scope][name][type] = o
      elsif obj = namespace.children.find {|o| o.name == meth.to_sym && o.scope == scope }
        # register an existing method as attribute
        namespace.attributes[scope][name][type] = obj
      end
    end
  end
end
