
define kdmrc($section=undef, $key=$name, $value=undef, $ensure=present) {
    line_config { "kdmrc: [$section] $key":
        provider => "ini",
        path     => "/etc/kde4/kdm/kdmrc",
        ensure   => $ensure,
        key      => $key,
        value    => $value,
        section  => $section,
        replace  => [ "^\\s*$key\\s*=", "^\\s*#\\s*$key\\s*=" ],
        require  => Package["kdm"],
        ignore   => [],
    }
}
