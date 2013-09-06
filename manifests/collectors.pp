
class nagios::collectors (
  $environmet_aware = false,
  $time_aware       = false,
){

  if $environment_aware {

    Nagios_host <<| tag == "env_$environment" |>> {
      notify  => Service[$nagios::params::servicename],
    }

    Nagios_service <<| tag == "env_$environment" |>> {
      notify  => Service[$nagios::params::servicename],
    }

    File <<| tag == "env_nagios_$environment" |>> {
    }

  } else {

    Nagios_host <<|  |>> {
      notify  => Service[$nagios::params::servicename],
    }

    Nagios_service <<|  |>> {
      notify  => Service[$nagios::params::servicename],
    }

    File <<| tag == "env_nagios" |>> {
    }

  }

}
