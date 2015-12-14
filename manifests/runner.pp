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
) {
  validate_string($package_name)
  validate_absolute_path($installroot)

  Exec {
    path => '/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/bin',
  }

  anchor { 'sonarqube::runner::begin': } ->
  class { '::sonarqube::runner::install':
    package_name => $package_name,
    version      => $version,
    download_url => $download_url,
    installroot  => $installroot,
  } ->
  class { '::sonarqube::runner::config':
    package_name     => $package_name,
    version          => $version,
    installroot      => $installroot,
    jdbc             => $jdbc,
    sonarqube_server => $sonarqube_server,
  } ~>
  anchor { 'sonarqube::runner::end': }
}
