require File.join(File.dirname(__FILE__), '..', 'line_config')

Puppet::Type.type(:line_config).provide(:ini, :parent => Puppet::Provider::LineConfig) do
    has_feature :section
    has_feature :keyval
    desc ""

    def setup
        @resource.default_ignore "^\\s*#"

        if @resource[:key]
            @resource.default_replace "^\\s*#{Regexp.escape(@resource[:key].to_s)}\\s*="
        end

        if @resource[:key] and @resource[:value]
            @resource.default_content "#{@resource[:key].to_s}=#{@resource[:value].to_s}"
            @resource.append_accepts %Q<^\\s*#{Regexp.escape(@resource[:key].to_s)}\\s*=\\s*['"]?#{Regexp.escape(@resource[:value].to_s)}["']?\\s*$>
        end
    end

    def content_with_section
        return content unless @resource[:section]
        "[#{@resource[:section].to_s}]\n#{@resource[:content].to_s.chomp}\n"
    end

    def flip_flop_init
        @ff = false
    end

    def flip_flop(line)
        return @ff = true  unless @resource[:section]
        return @ff = false unless line

        if line =~ /^\[#{Regexp.escape(@resource[:section].to_s)}\]/
            @ff = true
            return false
        elsif line =~ /^\[/
            @ff = false
        end
        return @ff
    end

end
