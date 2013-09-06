# Yes you might be using icinga, we're still calling it nagios
# It really _should_ work though
# Or at least thats the goal
class nagios::server(
  $readonly_web                  = true,
  $manage_package                = false,
  $manage_package_with_singleton = false,
  $manage_service                = false,
  $manage_resource_cfg           = false,
  $plugindir                     = '/usr/lib/nagios/plugins'
  $configuration_root            = '/etc/nagios3/',
  $purge_existing_configs        = true,
  $flat_repository               = true,
  $flat_repository_vcs           = false, # set to vcs type, e.g git
  $flat_repository_src           = '',
  $owner                         = 'nagios',
  $group                         = 'nagios',
){

  $nagiosuser = hiera('nagiosuser', 'zort')
  $mysqlpass  = hiera('nagiosuser_mysql_password', 'blorp')
  $pgpass     = hiera('nagiosuser_pg_password', 'foo')
  $smbpass    = hiera('nagiosuser_smb_password', 'bar')


  if $manage_package {

    pacakge { $nagios::params::packagename:
      ensure => latest,
    }

    # the root folder under which all nagios configs live
    file { "${configuration_root}/conf.d":
      owner   => nagios,
      group   => nagios,
      mode    => '6755',
      require => Package['nagios3'],
    }
  }

  if $manage_package_with_singleton {

    singleton_resources(
      Package['nagios3']
    )

    file { "${configuration_root}/conf.d":
      owner   => nagios,
      group   => nagios,
      mode    => '6755',
      require => Package['nagios3'],
    }

  }

  if $manage_service {

    service { 'nagios3':
      ensure  => running,
      enable  => true,
      restart => '/usr/sbin/service nagios3 reload',
      require => Package['nagios3'],
    }

  }

  if $manage_resource_cfg {

    # nagios plugin passwords
    file { '/etc/nagios3/resource.cfg':
      mode    => '0700',
      owner   => nagios,
      group   => nagios,
      content => template('nagios/resource.cfg.erb'),
      require => Package['nagios3'],
    }

  }


  # This folder is managed in git, it is for hosts and
  # services too unique to manage with puppet or a script
  # it is the nagios-configs git repository
  # This is not being managed with a vcsrepo resource at
  # this time
  # another directory, /etc/nagios-plugins/config is where
  # nagios-core, site written, and external nagios plugins
  # live
  if $flat_repository {

    file { '/etc/nagios3/conf.d/flat':
      owner   => nagios,
      group   => nagios,
      mode    => '6755',
      require => File['/etc/nagios3/conf.d'],
    }

    if $flat_repository_vcs {

      # clone in the nagios-plugins
      # updates managed by git hook not puppet
      vcsrepo { "${configuration_root}/conf.d/flat":
        ensure    => present,
        provider  => #flat_repository_vcs,
        user      => $owner,
        source    => $flat_repository_source,
        require   => Package['nagios3'],
      }
    }

  }

  # We should not be mucking with this, apt wants to
  # clone in the nagios-plugins
  # updates managed by git hook not puppet
  #vcsrepo { '/etc/nagios-plugins/config':
  #  ensure    => present,
  #  provider  => git,
  #  user      => 'nagios',
  #  source    => 'git@somewhere:nagios-plugins',
  #  require   => Package['nagios3'],
  #}

  file { '/usr/share/nagios3/htdocs/images/logos':
    owner   => nagios,
    group   => nagios,
    mode    => '6755',
    require => Package['nagios3'],
  }

  # clone in the nagios icons
  # updates managed by git hook not puppet
  vcsrepo { '/usr/share/nagios3/htdocs/images/logos/extras':
    ensure    => present,
    provider  => git,
    user      => 'nagios',
    source    => 'git@github.com:pdxcat/nagios-icons',
    require   => File['/usr/share/nagios3/htdocs/images/logos'],
  }

  file { '/usr/share/nagios3/htdocs/images/logos/logos':
    ensure    => symlink,
    require   => Package['nagios3'],
    target    => '../../../../nagios/htdocs/images/logos/logos',
  }


  #needed for the git sync stuff to work in nagios-plugins
  #file { '/etc/nagios-plugins/config/.git-sync-stamp':
  #  ensure  => present,
  #  owner   => nagios,
  #  group   => nagios,
  #  mode    => '0644',
  #  require => Vcsrepo['/etc/nagios-plugins/config'],
  #}

  #needed for the git sync stuff to work in nagios-configs
  file { '/etc/nagios3/conf.d/flat/.git-sync-stamp':
    ensure  => present,
    owner   => nagios,
    group   => nagios,
    mode    => '0644',
    require => Vcsrepo['/etc/nagios3/conf.d/flat'],
  }



  # This folder is where puppet resources are kept, for
  # sanity
  file { '/etc/nagios3/conf.d/puppet':
    ensure  => directory,
    owner   => nagios,
    group   => nagios,
    recurse => true,
    require => File['/etc/nagios3/conf.d'],
  }

  # Need a stanza here for arbitrary plugins to be placed in
  # something like
  #file { '/etc/nagios-plugins/check_nexenta.cfg':
  #  content => template('nagios/check_nexenta.cfg.erb'),
  #  group   => nagios,
  #  owner   => nagios,
  #  require => Package['nagios3'],
  #}


  # This allows the nagios user to log in
  pam::access { 'nagios':
    permission  => '+',
    entity      => 'nagios',
    origin      => 'ALL';
  }

  if $purge_existing_configs {
    # These files are provided by the nagios-common pkg and
    # need to be nuked

    $not_these_files = [
      "/etc/nagios3/conf.d/contacts_nagios2.cfg",
      "/etc/nagios3/conf.d/extinfo_nagios2.cfg",
      "/etc/nagios3/conf.d/generic-host_nagios2.cfg",
      "/etc/nagios3/conf.d/generic-service_nagios2.cfg",
      "/etc/nagios3/conf.d/hostgroups_nagios2.cfg",
      "/etc/nagios3/conf.d/localhost_nagios2.cfg",
      "/etc/nagios3/conf.d/services_nagios2.cfg",
      "/etc/nagios3/conf.d/timeperiods_nagios2.cfg",
    ]

    file { $not_these_files:
      ensure => absent,
    }
  }

  # the following is for enabling write access to the web gui
  if $readonly_web == false {

    file_line {
      '/etc/nagios3/nagios.cfg-external-commands-yes':
        line    => 'check_external_commands=1',
        path    => '/etc/nagios3/nagios.cfg',
        notify  => Service['nagios3'],
        require => Package['nagios3'];

      '/etc/nagios3/cgi.cfg-all_service_commands':
        line    => 'authorized_for_all_host_commands=nagiosadmin',
        path    => '/etc/nagios3/cgi.cfg',
        notify  => Service['nagios3'],
        require => Package['nagios3'];

      '/etc/nagios3/cgi.cfg-all_host_commands':
        line    => 'authorized_for_all_service_commands=nagiosadmin',
        path    => '/etc/nagios3/cgi.cfg',
        notify  => Service['nagios3'],
        require => Package['nagios3'];
    }

    user { 'nagios':
      groups      => ['nagios', 'www-data'],
      membership  => minimum,
      require     => Package['nagios3'];
    }

    file { '/var/lib/nagios3/rw':
      ensure  => directory,
      group   => 'www-data',
      mode    => '2710',
      owner   => 'nagios',
      require => Package['nagios3'];
    }

    file { '/var/lib/nagios3':
      ensure  => directory,
      group   => 'nagios',
      mode    => '0751',
      owner   => 'nagios',
      require => Package['nagios3'];
    }

    file { '/usr/lib/nagios/plugins/utils.pm':
      group   => 'root',
      mode    => '0644',
      owner   => 'root',
      require => Package['nagios3'],
      source  => "puppet://$server/modules/nagios/utils.pm";
    }

  }

}
