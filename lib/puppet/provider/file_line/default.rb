require File.join(File.dirname(__FILE__), '..', 'file_line')

Puppet::Type.type(:file_line).provide(:default, :parent => Puppet::Provider::FileLine) do
    has_feature :keyval
    desc ""

    def setup
        @resource.default_ignore "^\\s*#"

        if @resource[:key]
            @resource.default_replace "^\\s*#{Regexp.escape(@resource[:key])}\\s*="
        end

        if @resource[:key] and @resource[:value]
            @resource.default_content "#{@resource[:key]}=#{@resource[:value]}"
        end
    end

end
