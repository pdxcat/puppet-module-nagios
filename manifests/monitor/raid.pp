class nagios::monitor::raid {

  include nrpe::params

  file { 'check_md_raid':
    ensure => present,
    mode   => '0755',
    path   => "${nrpe::params::libdir}/check_md_raid",
    source => "puppet://${::server}/modules/nagios/check_md_raid",
  }

  if $::raidtype == 'software' {
    nagios::monitor { 'check_raid':
      check_command       => 'nrpe_check_raid',
      nrpe                => true,
      service_description => 'Check software raid',
      use                 => $s_use,
    }

    if ( $::selinux == 'true' ) {
      semodloader::semodule {'nrpe_mdstat_local':
        source => [
          "puppet://${::server}/modules/nagios/check_md_raid.te.${::osfamily}${::os_maj_version}",
          "puppet://${::server}/modules/nagios/check_md_raid.te"
        ],
        status => 'present',
      }
    }

  }



}
