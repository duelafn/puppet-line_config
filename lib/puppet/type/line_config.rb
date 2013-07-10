# -*- coding: utf-8 -*-
require 'puppet/util/backups'
require 'fileutils'

Puppet::Type.newtype(:line_config) do
    include Puppet::Util::Backups

    attr_accessor :current_value_s, :target_value_s

    @doc = %q!Manipulate individual lines of a file

BEWARE: This sort of manipulation can greatly increase the chance of
unintentional conflict where two different parts of your puppet config try
to set conflicting data. For instance, one part of your config sets a
variable to one value and another part sets it to something else. If you do
this, the result is undefined since, under most circumstances, the
execution order of puppet is undefined.

One way to combat this is to standardize your naming by CONSTANT VIGILANCE
(I recommend "filename: keyname") or by using "define" to create a custom
subtype.


Autorequires: File resource with same path as this resource. Currently,
this is the only way to control ownership and permissions of the config
file.

Examples:

# sets general.smoothScroll to false.
# ignores all comment lines
# will replace any existing general.smoothScroll setting
line_config { "/home/duelafn/etc/mozilla/user.js: general.smoothScroll":
    provider => "basic",
    path     => "/home/duelafn/etc/mozilla/user.js",
    content  => 'user_pref("general.smoothScroll", false);',
    ignore   => "^\\s*//",
    replace  => "[\\"']general\\.smoothScroll[\\"']",
}

# manage individual fstab entries
line_config { "/etc/fstab: /SHARE":
    path     => "/etc/fstab",
    content  => "//192.168.100.10/shared    /SHARE    smbfs    username=guest,password=,uid=guest    0    0",
    replace  => "\\s/SHARE\\s",
}

# default provider replaces /^\s*KEY\s*=/ with "KEY=VALUE"
# default provider ignores lines matching /^\s*#/
line_config { "/etc/adduser.conf: DHOME":
    path     => "/etc/adduser.conf",
    key      => "DHOME",
    value    => "/nfs/home",
}

# Set a default value only if missing, ignore if file not present
line_config { "/etc/abcde.conf: OUTPUTTYPE":
    path     => "/etc/abcde.conf",
    ensure   => "set",
    key      => "OUTPUTTYPE",
    value    => "ogg",
    nofile   => "ignore",
}

# Sets "DefaultUser=guest" in corresponding section
line_config { "kdmrc: DefaultUser":
    provider => "ini",
    path     => "/etc/kde4/kdm/kdmrc",
    section  => "X-:0-Greeter",
    key      => "DefaultUser",
    value    => "guest",
}

# Ensure AutoLoginUser is missing from all sections
line_config { "kdmrc: Auto-login":
    provider => "ini",
    ensure   => "unset",
    path     => "/etc/kde4/kdm/kdmrc",
    key      => "NoPassUsers",
}


# Use a define to make config settings quite nice:
# Use a custom replace to replace both commented and uncommented instances
define kdmrc($section=undef, $key=$name, $value=undef, $ensure=present) {
    line_config { "kdmrc: [$section] $key":
        provider => "ini",
        path     => "/etc/kde4/kdm/kdmrc",
        ensure   => $ensure,
        key      => $key,
        value    => $value,
        section  => $section,
        ignore   => [],
        replace  => [ "^\\s*$key\\s*=", "^\\s*#\\s*$key\\s*=" ],
        require  => Package["kdm"],
    }
}

kdmrc { "NoPassUsers": ensure => "unset" }
kdmrc { "DefaultUser":
    value => "guest",
    section => "X-:0-Greeter"
}

!

    feature :section, "The ability to section."
    feature :keyval,  "The ability to turn key/val into a line."

    autorequire(:file) do
        [ self[:path] ]
    end

    ensurable do
        desc 'Accepted values:
present - content (or "accepts") appears in file
absent  - content (or "accepts") does not appear in file
set     - (requires "keyval" feature) the key is set. value parameter is used only as a default.
unset   - (requires "keyval" feature) the key is not set. value parameter is not used.
'
        defaultto :present

        def retrieve
            prov = @resource.provider
            return :nofile unless File.exists? @resource.value(:path)
            if prov
                return prov.get_state
            else
                raise Puppet::Error, "Could not find provider"
            end
        end

        def insync?(is)
            return true if is == should
            return true if is == :nofile and @resource.value(:nofile) == :ignore

            case should
            when :absent
                return true if [:unset, :absent, :nofile].include?(is)
            when :set
                return true if [:set, :present].include?(is)
            end

            return false
        end

        def is_to_s(value)
            @resource.current_value_s || value
        end

        def should_to_s(value)
            case value
            when :absent, :unset
                return value
            else
                return @resource.target_value_s || value
            end
        end

        newvalue :present do
            FileUtils.touch @resource.value(:path)
            provider.insert
        end

        newvalue :absent do
            provider.remove
        end

        newvalue :set, :required_features => [:keyval] do
            FileUtils.touch @resource.value(:path)
            provider.set
        end

        newvalue :unset, :required_features => [:keyval] do
            provider.unset
        end
    end

    newparam(:name) do
        isnamevar
    end

    newparam(:path, :parent => Puppet::Parameter::Path) do
        desc "Path of the file to modify."
    end

    newparam(:section, :required_features => %w{section}) do
        desc "Section of file to restrict search to."
    end

    newparam(:content) do
        desc "Line content to insert."
    end

    newparam(:key, :required_features => %w{keyval}) do
        desc "Key name."
    end

    newparam(:value, :required_features => %w{keyval}) do
        desc "Value."
    end

    newparam(:ignore) do
        desc "Regexp of lines to ignore when searching."

        munge do |value|
            [*value].map { |x| Regexp.new(x) }
        end
    end

    newparam(:accept) do
        desc "Regexp matching lines which should be considered equivalent to this value."

        defaultto []

        munge do |value|
            [*value].map { |x| Regexp.new(x) }
        end
    end

    newparam(:replace) do
        desc "Regexp matching lines which should be replaced by this value."

        munge do |value|
            [*value].map { |x| Regexp.new(x) }
        end
    end

    newparam(:nofile) do
        desc "Behavior when file does not exist. Default is 'error'. May set to 'ignore' to skip configuration if file is missing."

        defaultto :error

        munge do |value|
            value =~ /^ignore/i ? :ignore : :error
        end
    end


    def initialize(hash)
        super

        unless self[:provider]
            if self[:path] =~ /\.ini$/
                self[:provider] = "ini"
            end
        end
        self[:provider] ||= "default"

        if self[:content]
            content_re = Regexp.new("^#{Regexp.escape(self[:content])}$")
            self[:accept].push(content_re)
            @target_value_s = self[:content]
        end

        provider.setup if provider.respond_to? :setup
    end

    validate do
        self.fail "You must specify a path" unless self[:path]

        self.fail "You cannot specify both content and a key/value" if self[:content] and (self[:key] or self[:value])

        provider.validate if provider.respond_to? :validate
    end

    def self.instances
        []
    end

    def default_content(value)
        unless self[:content]
            self[:content] = value
            append_accepts("^#{Regexp.escape(value)}$")
            @target_value_s = self[:content]
        end
    end

    def append_accepts(pattern)
        self[:accept].push(Regexp.new(pattern))
    end

    def default_ignore(pattern)
        self[:ignore] ||= [ Regexp.new(pattern) ]
    end

    def default_replace(pattern)
        self[:replace] ||= [ Regexp.new(pattern) ]
    end

end
