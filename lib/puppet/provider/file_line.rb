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

    def get_state
        state = :unset
        read_lines do |line|
            if accepts? line
                @resource.current_value_s = line.chomp
                return state = :present
            elsif state != :present and replaces? line
                @resource.current_value_s = line.chomp
                state = :set
            end
        end
        return state
    end

    def content
        "#{@resource[:content].chomp}\n"
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

end
