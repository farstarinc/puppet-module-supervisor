define supervisor::group(
  $enable=true, $ensure=present,
  $programs, $priority=999,
  $conf_dir=undef) {

  include supervisor::params

    if (!$conf_dir) {
      $conf_dir = $supervisor::params::conf_dir
    }

    if ! defined(File[$conf_dir]) {
      file { $conf_dir:
        ensure => directory,
        purge => true,
      }
    }

    file {
      "${conf_dir}/${name}.conf":
        ensure => $enable ? {
          false => absent,
          default => undef },
        content => $enable ? {
          true => template('supervisor/group.conf.erb'),
          default => undef },
        require => File[$conf_dir],
        notify => Exec['supervisor::update']
    }

    if ($ensure == 'running' or $ensure == 'stopped') {
      service {
        "supervisor::${name}":
          ensure   => $ensure,
          provider => base,
          restart  => "/usr/bin/supervisorctl restart ${name}",
          start    => "/usr/bin/supervisorctl start ${name}",
          status   => "/usr/bin/supervisorctl status | awk '/^${name}/{print \$2}' | grep '^RUNNING$'",
          stop     => "/usr/bin/supervisorctl stop ${name}",
          require  => [ Package['supervisor'], Service[$supervisor::params::system_service] ];
      }
    }
  }
