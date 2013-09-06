puppet-module-nagios
====================

Puppet module to manage nagios/icinga.

Can run the whole server, or

Can setup nagios checks using exported resources.

Exposes a couple types that make monitoring really easy and fun again 

Requires NRPE monitor


# see server.pp for managing the nagios install
# see client.pp for a base client class
# see monitor.pp for a monitoring define
# see collectors.pp for a class to only collect exported resources, not manage nagios
