require File.join(File.dirname(__FILE__), '..', 'file_line')

Puppet::Type.type(:file_line).provide(:basic, :parent => Puppet::Provider::FileLine) do
    desc ""

end
