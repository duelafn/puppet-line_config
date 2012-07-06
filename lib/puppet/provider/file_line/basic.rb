require File.join(File.dirname(__FILE__), '..', 'file_line')

Puppet::Type.type(:file_line).provide(:basic, :parent => Puppet::Provider::FileLine) do
    desc ""

    def insert
        inserted = false
        munge_lines do |line|
            if !inserted and !line
                inserted = true
                content
            elsif replaces?(line)
                inserted = true
                content
            elsif !inserted and accepts?(line)
                inserted = true
                line
            else
                line
            end
        end
    end

    def remove
        munge_lines do |line|
            if accepts?(line)
                nil
            else
                line
            end
        end
    end

end
