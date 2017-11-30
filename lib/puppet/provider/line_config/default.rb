require File.join(File.dirname(__FILE__), '..', 'line_config')

Puppet::Type.type(:line_config).provide(:default, :parent => Puppet::Provider::LineConfig) do
    has_feature :keyval
    desc ""

    defaultfor :feature => :posix

    def setup
        @resource.default_ignore "^\\s*#"

        if @resource[:key]
            @resource.default_replace "^\\s*#{Regexp.escape(@resource[:key].to_s)}\\s*="
        end

        if @resource[:key] and @resource[:value]
            @resource.default_content "#{@resource[:key].to_s}=#{@resource[:value].to_s}"
        end
    end

end
