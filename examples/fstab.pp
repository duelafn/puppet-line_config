
define fstab($mount=$name, $device, $type, $ensure=present, $options=defaults, $dump=0, $pass=0) {
    file_line { "/etc/fstab: $mount":
        ensure => $ensure,
        path => "/etc/fstab",
        content => "$device   $mount   $type   $options    $dump    $pass",
        replace  => "\\s$mount\\s",
    }
}
