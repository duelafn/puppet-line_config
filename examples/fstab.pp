
define fstab($mount=$name, $device, $type, $options=defaults, $dump=0, $pass=0) {
    file_line { "/etc/fstab: $mount":
        path => "/etc/fstab",
        content => "$device   $mount   $type   $options    $dump    $pass",
        replace  => "\\s$mount\\s",
    }
}
