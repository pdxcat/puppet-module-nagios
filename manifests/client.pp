class nagios::client(
  $hostgroups      = 'puppetboxes',
  $contact_groups  = 'splatnix',
  $notifications   = '24/7',
  $check_load      = true,
  $check_rootSpace = true,
  $check_varSpace  = true,
  $nrpe_servers    = ["nagios.${domain}"],
  $nrpe_commands   = undef,
  $target          = "/etc/nagios3/conf.d/puppet/${::fqdn}_s.cfg",
  $owner           = 'nagios',
  $group           = 'nagios',
){

  include nagios::monitor::raid

  #notification type table
  case $notifications {
    '24/7': {
      $use = 'host-247'
      $s_use = 'service-247'
    }
    '9-10/weekday': {
      $use = 'host-910'
      $s_use = 'service-910'
    }
    'irconly': {
      $use = 'host-irconly'
      $s_use = 'service-irconly'
    }
    default:         { fail('Specify a notification timetable, squidbrain!') }
  }

  include fact::setup

  if ( $::nagios_enabled ) {
    @@file { "${fqdn}_nagios_host_file":
      ensure  => present,
      backup  => false,
      owner   => $owner,
      group   => $owner,
      path    => $target,
      tag     => "env_nagios_$environment",
    }

    @@file { "${fqdn}_nagios_service_file":
      ensure  => present,
      backup  => false,
      owner   => $owner,
      group   => $owner,
      path    => $target,
      tag     => "env_nagios_$environment",
    }
  }

  # nagios icons
  $icon = $::operatingsystem ? {
    'centos'  => 'centos.png',
    'darwin'  => 'mac40.png',
    'freebsd' => 'freebsd40.png',
    'redhat'  => 'redhat.png',
    'solaris' => 'sun40.png',
    'ubuntu'  => 'ubuntu.png',
    default   => 'linux40.png',
  }

  # nagios status map icons
  $mapicon = $::operatingsystem ? {
    'centos'  => 'centos.gd2',
    'darwin'  => 'mac40.gd2',
    'freebsd' => 'freebsd40.gd2',
    'redhat'  => 'redhat.gd2',
    'solaris' => 'sun40.gd2',
    'ubuntu'  => 'ubuntu.gd2',
    default   => 'linux40.gd2',
  }



  # FIXME hack for now, this assumes all kvms are part of "The cloud"

  if ( $::virtual == 'kvm' ) {
    $nagios_parents = hiera('cloud_parents')
  } else {
    $nagios_parents = hiera('nagios-parent-of-all-things')
  }

  $nagios_base_hostgroup = hiera('nagios_base_hostgroup')

  if ( $::nagios_enabled ) {
    @@nagios_host { "${fqdn}_nagios_host":
      ensure          => present,
      address         => $dns_ip_4,
      alias           => $hostname,
      host_name       => $hostname,
      hostgroups      => "${nagios_base_hostgroup},${hostgroups}",
      icon_image      => "base/${icon}",
      parents         => $nagios_parents,
      require         => File["/etc/nagios3/conf.d/puppet/${fqdn}.cfg"],
      statusmap_image => "base/${mapicon}",
      tag             => "env_${environment}",
      target          => "/etc/nagios3/conf.d/puppet/${fqdn}.cfg",
      use             => $use,
    }

    if $dns_ip_6 != '' {
      @@nagios_host { "${fqdn}_nagios_host_6":
        ensure          => present,
        address         => $dns_ip_6,
        alias           => "${hostname}6",
        host_name       => "${hostname}6",
        hostgroups      => "${nagios_base_hostgroup},${hostgroups}",
        icon_image      => "base/${icon}",
        parents         => $hostname,
        require         => File["/etc/nagios3/conf.d/puppet/${fqdn}.cfg"],
        statusmap_image => "base/${mapicon}",
        tag             => "env_${environment}",
        target          => "/etc/nagios3/conf.d/puppet/${fqdn}.cfg",
        use             => $use,
      }
    }
  }

  # FIXME 2013/6/13
  # I thought about adding it to the nrpe module
  # but I don't know how to handle an array of allowed_hosts
  # because at this time the firewall module doesn't support
  # an array of ip addresses for the source parameter
  case $::osfamily {
    'redhat': {
      nagios::nrpefirewall { $nrpe_servers: }
    }
    default: {}
  }

  # Install nrpe daemon
  class { 'nrpe':
    # Allow monitoring hosts and localhost
    allowed_hosts => [$nrpe_servers, '127.0.0.1'], # Yea, I just did that, umad?
    purge         => true,
    recurse       => true,
  }

  # Install general check scripts
  nrpe::command {
      'check_users':
        command => 'check_users -w 5 -c 10';
      'check_load':
        command => 'check_load -w 55,55,55 -c 100,90,80';
      'check_root':
        command => 'check_disk -w 10% -c 3% -p /';
      'check_var':
        command => 'check_disk -w 10% -c 3% -p /var';
      'check_raid':
        command => 'check_md_raid';
  }

  # Install user supplied check scripts
  if $nrpe_commands != undef {
    create_resources(nrpe::command, $nrpe_commands)
  }

  if ($check_load) {
    # Nagios checks for all hosts
    naigos::monitor { 'load_check':
      check_command       => 'nrpe_check_load',
      nrpe                => true,
      service_description => 'LOAD',
      use                 => $s_use,
    }
  }

  if ($check_varSpace){
    nagios::monitor { 'check_var':
      check_command       => 'nrpe_check_var',
      nrpe                => true,
      service_description => 'Free space in var',
      use                 => $s_use,
    }
  }

  if ($check_rootSpace){
    nagios::monitor { 'check_root':
      check_command       => 'nrpe_check_root',
      nrpe                => true,
      service_description => 'Free space in /',
      use                 => $s_use,
    }
  }

}
