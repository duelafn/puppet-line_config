# -*- coding: utf-8 -*-
require 'fileutils'
require 'tempfile'

class Puppet::Provider::FileLine < Puppet::Provider

    def accepts?(line)
        return false unless line and @resource[:accept]
        @resource[:accept].each do |accept|
            return true if accept.match(line)
        end
        return false
    end

    def ignores?(line)
        return true  unless line
        return false unless @resource[:ignore]
        @resource[:ignore].each do |ignore|
            return true if ignore.match(line)
        end
        return false
    end

    def replaces?(line)
        return false unless line and @resource[:replace]
        @resource[:replace].each do |replace|
            return true if replace.match(line)
        end
        return false
    end

    def content
        "#{@resource[:content].chomp}\n"
    end

    def content_with_section
        content
    end

    def flip_flop_init
        @ff = true
    end

    def flip_flop(line)
        true
    end

    def read_lines
        File.open(@resource[:path], "r") do |fh|
            fh.each do |line|
                next if ignores? line
                yield(line)
            end
        end
    end

    def munge_lines
        target = @resource[:path]
        stat = File.stat(target)
        file = Tempfile.new(File.basename(target))
        file.chmod(stat.mode)
        file.chown(stat.uid, stat.gid)
        begin
            File.open(target, "r") do |fh|
                fh.each do |line|
                    if ignores? line
                        res = line
                    else
                        res = yield(line)
                    end
                    file.write(res) if res
                end

                res = yield(nil)
                file.write(res) if res
            end
        rescue
            file.close
            file.unlink
            raise
        else
            file.close
            FileUtils.mv file.path, target, :force => true
        end
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
