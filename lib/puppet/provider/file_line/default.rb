
Puppet::Type.type(:file_line).provide(:default, :parent => :basic) do
    has_feature :keyval
    desc ""

    def setup
        @resource.default_ignore "^\s*#"

        if @resource[:key]
            @resource.default_replace "^\s*#{Regexp.escape(@resource[:key])}\s*="
        end

        if @resource[:key] and @resource[:value]
            @resource.default_content "#{@resource[:key]}=#{@resource[:value]}"
        end
    end

    def set
        insert
    end

    def unset
        munge_lines do |line|
            if accepts?(line) or replaces?(line)
                nil
            else
                line
            end
        end
    end

end
