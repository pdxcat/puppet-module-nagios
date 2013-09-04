define nagios::monitor::create_commands {

  $zpool_name = $name

  if $zpool_name == $::hostname {
    nrpe::command { 'check_zfs':
      command => "check_zfs ${zpool_name} 2",
    }
    nagios::monitor { "check_zfs_${zpool_name}":
      check_command       => 'solaris_check_zpool',
      nrpe                => true,
      service_description => "Zpool health ${zpool_name}",
      servicegroups       => 'zpools',
      use                 => 'service-247',
    }
  } else {
    nrpe::command { "check_zfs_${zpool_name}":
      command => "check_zfs ${zpool_name} 2",
    }
    nagios::monitor { "check_zfs_${zpool_name}":
      check_command       => "check_zfs_${zpool_name}",
      nrpe                => true,
      servicegroups       => 'zpools',
      service_description => "Zpool health ${zpool_name}",
      use                 => 'service-247',
    }
  }


}
