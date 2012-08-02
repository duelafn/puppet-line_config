
exec { "update-grub": refreshonly => true }

define grubconfig($key=$name, $value=undef, $ensure=present) {
    file_line { "grub: $key":
        path     => '/etc/default/grub',
        ensure   => $ensure,
        key      => $key,
        value    => $value,
        replace  => [ "^\\s*$key\\s*=", "^\\s*#\\s*$key\\s*=" ],
        ignore   => [],
        notify   => Exec["update-grub"],
    }
}
