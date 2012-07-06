require File.join(File.dirname(__FILE__), '..', 'file_line')

Puppet::Type.type(:file_line).provide(:ini, :parent => Puppet::Provider::FileLine) do
    has_feature :section
    has_feature :keyval
    desc ""

    def setup
        @resource.default_ignore "^\\s*#"

        if @resource[:key]
            @resource.default_replace "^\\s*#{Regexp.escape(@resource[:key])}\\s*="
        end

        if @resource[:key] and @resource[:value]
            @resource.default_content "#{@resource[:key]}=#{@resource[:value]}"
            @resource.append_accepts %Q<^\\s*#{Regexp.escape(@resource[:key])}\\s*=\\s*['"]?#{Regexp.escape(@resource[:value])}["']?\\s*$>
        end
    end

    def content_with_section
        return content unless @resource[:section]
        "[#{@resource[:section]}]\n#{@resource[:content].chomp}\n"
    end

    def flip_flop_init
        @ff = false
    end

    def flip_flop(line)
        return @ff = true  unless @resource[:section]
        return @ff = false unless line

        if line =~ /^\[#{Regexp.escape(@resource[:section])}\]/
            @ff = true
            return false
        elsif line =~ /^\[/
            @ff = false
        end
        return @ff
    end

end
