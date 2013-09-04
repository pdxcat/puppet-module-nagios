define nagios::monitor::zpool (
  $zpool_names,
){

  include nrpe::params
  # only works on solaris right now

  nagios::monitor::create_commands { $zpool_names:; }

  file { 'check_zfs':
    ensure => present,
    mode   => '0755',
    path   => "${nrpe::params::libdir}/check_zfs",
    source => "puppet://${::server}/modules/cecs/monitor/check_zfs",
  }


  if ( $::operatingsystem == 'Solaris' ) {
    package { 'CSWsudo':
      ensure   => installed,
      provider => pkgutil,
    }

    file { '/etc/opt/csw/sudoers':
      group   => 'root',
      owner   => 'root',
      require => Package['CSWsudo'],
    }

    $package = 'CSWsudo'
    $sudoers = '/etc/opt/csw/sudoers.d'
  } else {

    package { 'sudo':
      ensure  => installed,
    }

    $package = 'sudo'
    $sudoers = '/etc/sudoers.d'
  }

  file { 'sudo_nagios':
    ensure  => present,
    group   => 'root',
    mode    => '0440',
    owner   => 'root',
    path    => "${sudoers}/nagios",
    require => Package[$package],
    source  => "puppet://${::server}/modules/cecs/monitor/sudoers.d/nagios",
  }


}
