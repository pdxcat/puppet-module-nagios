define nagios::nrpefirewall (
  $nrpe_server,
){

  firewall {
    '241 ipv4 allow nrpe port for drkatz':
      chain  => 'INPUT',
      proto  => 'tcp',
      dport  => '5666',
      source => [$nrpe_server],
      action => 'accept';
  }

}
