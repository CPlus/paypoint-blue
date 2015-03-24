class ShortcutHandler < YARD::Handlers::Ruby::Base
  handles method_call(:shortcut)
  namespace_only

  def process
    unless namespace.docstring.index('== Payload Shortcuts')
      namespace.docstring += "\n\n== Payload Shortcuts\n"
    end
    shortcut = statement.parameters.first.jump(:ident).source
    path = statement.parameters[1].jump(:string_content).source
    namespace.docstring += "\n[+:#{shortcut}+] +#{path}+"
  end
end
