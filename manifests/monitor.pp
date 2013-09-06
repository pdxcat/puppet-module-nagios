define nagios::monitor (
  $check_command,
  $service_description,
  $disable_fact_check   = true,
  $ensure               = 'present',
  $nrpe                 = false,
  $servicegroups        = undef,
  $target               = "/etc/nagios3/conf.d/puppet/${::fqdn}_s.cfg",
  $use                  = 'service-247',
  $tag_with_environment = false,
) {

  include fact::setup

  if $tag_with_environment {
    $resource_tag = "env_${environment}"
  }

  if ( $::nagios_enabled || $disable_fact_check ) {
    @@nagios_service { "${::fqdn}_nagios_service_${title}":
      ensure              => $ensure,
      target              => $target,
      host_name           => $hostname,
      check_command       => $check_command,
      service_description => $service_description,
      use                 => $use,
      tag                 => $resource_tag,
      require             => File[$target],
      servicegroups       => $servicegroups,
      max_check_attempts  => $nrpe ? {
        true    => 10,
        false   => 2,
        default => 2,
      },
    }

    if $dns_ip_6 != '' and ! $nrpe {
      @@nagios_service { "${fqdn}_nagios_service_${title}_6":
        ensure              => $ensure,
        target              => $target,
        host_name           => "${hostname}6",
        check_command       => $check_command,
        service_description => "${service_description}6",
        use                 => $use,
        tag                 => $resource_tag,
        require             => File[$target],
        servicegroups       => $servicegroups,
      }
    }
  }

}
