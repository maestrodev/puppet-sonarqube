class sonarqube::runner::install inherits sonarqube::runner {
  include wget

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
    require => Wget::Fetch['download-sonar-runner'],
  } ->

  # Sonar settings for terminal sessions.
  file { "/etc/environment":
    content => inline_template("SONAR_RUNNER_HOME=/usr/local/sonar-runner\nPATH=$PATH:/usr/local/sonar-runner/bin\n")
  }
}
