require File.join(File.dirname(__FILE__), '..', 'line_config')

Puppet::Type.type(:line_config).provide(:basic, :parent => Puppet::Provider::LineConfig) do
    desc ""

end
