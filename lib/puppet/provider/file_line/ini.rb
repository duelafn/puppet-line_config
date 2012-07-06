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

    def get_state
        state = :unset
        flip_flop_init

        read_lines do |line|
            flip_flop(line)
            if @ff and accepts? line
                @resource.current_value_s = line.chomp
                return state = :present
            elsif @ff and state != :present and replaces? line
                @resource.current_value_s = line.chomp
                state = :set
            end
        end
        return state
    end

    def insert
        inserted = false
        flip_flop_init

        munge_lines do |line|
            was_in_section = @ff
            flip_flop(line)

            if !line and !inserted
                was_in_section ? content : content_with_section

            elsif !@ff
                if was_in_section and !inserted
                    inserted = true
                    "#{content}\n" + line
                else
                    line
                end

            elsif @ff and replaces?(line)
                inserted = true
                content

            elsif @ff and !inserted and accepts?(line)
                inserted = true
                line

            else
                line
            end
        end
    end

    def remove
        flip_flop_init

        munge_lines do |line|
            if flip_flop(line) and accepts?(line)
                nil
            else
                line
            end
        end
    end

    def set
        insert
    end

    def unset
        flip_flop_init

        munge_lines do |line|
            if flip_flop(line) and (accepts?(line) or replaces?(line))
                nil
            else
                line
            end
        end
    end

end
