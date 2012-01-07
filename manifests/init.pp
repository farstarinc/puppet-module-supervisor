class supervisor ($use_upstart=false) {
  include supervisor::params

  if ! defined(Package[$supervisor::params::package]) { 
    package {"${supervisor::params::package}":
      ensure => installed
    }
  }

  file {
    $supervisor::params::conf_dir:
      ensure  => directory,
      purge   => true,
      require => Package[$supervisor::params::package];
    ['/var/log/supervisor',
     '/var/run/supervisor']:
      ensure  => directory,
      purge   => true,
      backup  => false,
      require => Package[$supervisor::params::package];
    $supervisor::params::conf_file:
      content => template('supervisor/supervisord.conf.erb'),
      require => Package[$supervisor::params::package],
      notify  => Service[$supervisor::params::system_service];
    '/etc/logrotate.d/supervisor':
      source => 'puppet:///modules/supervisor/logrotate',
      require => Package[$supervisor::params::package];
  }
  
  # if using upstart, service_name is always just "supervisor"
  $system_service = $use_upstart ? {
    true => "supervisor",
    default => $supervisor::params::system_service
  }

  service { $system_service:
      ensure     => running,
      enable     => true,
      hasrestart => true,
      require    => Package[$supervisor::params::package],
      provider   => $use_upstart ? {
        true => upstart,
        default => undef
      },
  }

  if ($use_upstart) {
    file { "/etc/init/supervisor.conf":
      content => template("supervisor/supervisord-upstart.conf.erb"),
      before => Service[$system_service],
    }
    file { "/etc/init.d/supervisor":
      ensure => absent
    }
  }

  exec {
    'supervisor::update':
      command     => '/usr/bin/supervisorctl update',
      logoutput   => on_failure,
      refreshonly => true,
      require     => Service[$supervisor::params::system_service];
  }
}
