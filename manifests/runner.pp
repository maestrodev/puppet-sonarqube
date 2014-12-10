# Class: sonarqube::runner
#
# Install the sonar-runner
class sonarqube::runner (
  $package_name     = 'sonar-runner',
  $version          = '2.4',
  $download_url     = 'http://repo1.maven.org/maven2/org/codehaus/sonar/runner/sonar-runner-dist',
  $installroot      = '/usr/local',
  $sonarqube_server = 'http://sonar.local:9000/',
  $jdbc             = {
    url      => 'jdbc:h2:tcp://localhost:9092/sonar',
    username => 'sonar',
    password => 'sonar',
  },
) inherits sonarqube::params {
  validate_string($package_name)
  validate_absolute_path($installroot)

  Exec {
    path => '/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/bin'
  }

  anchor { 'sonarqube::runner::begin': } ->
  class { '::sonarqube::runner::install':
    require => Class[ 'sonarqube' ],
  } ->
  class { '::sonarqube::runner::config': } ~>
  anchor { 'sonarqube::runner::end': }
}