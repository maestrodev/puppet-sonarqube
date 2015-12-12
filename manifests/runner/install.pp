# Installation of SonarQube Runner
class sonarqube::runner::install (
  $package_name,
  $version,
  $download_url,
  $installroot,
) {
  include wget

  if ! defined(Package[unzip]) {
    package { 'unzip':
      ensure => present,
      before => Exec[unzip-sonar-runner],
    }
  }

  $tmpzip = "/usr/local/src/${package_name}-dist-${version}.zip"

  wget::fetch { 'download-sonar-runner':
    source      => "${download_url}/${version}/sonar-runner-dist-${version}.zip",
    destination => $tmpzip,
  } ->

  file { "${installroot}/${package_name}-${version}":
    ensure => directory,
  } ->

  file { "${installroot}/${package_name}":
    ensure => link,
    target => "${installroot}/${package_name}-${version}",
  } ->

  exec { 'unzip-sonar-runner':
    command => "unzip -o ${tmpzip} -d ${installroot}",
    creates => "${installroot}/sonar-runner-${version}/bin",
    require => [Package[unzip], Wget::Fetch['download-sonar-runner']],
  }

  # Sonar settings for terminal sessions.
  file { '/etc/profile.d/sonarhome.sh':
    content => 'export SONAR_RUNNER_HOME=/usr/local/sonar-runner',
  }
  file { '/usr/bin/sonar-runner':
    ensure => link,
    target => '/var/lib/sonar-runner/bin/sonar-runner',
  }
}
