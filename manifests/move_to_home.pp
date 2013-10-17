# copy folders susceptible to change from installation folder to /var/local/sonar and symlink
define sonarqube::move_to_home() {
  file { "${sonarqube::home}/${name}":
      ensure => directory,
  } ->

  file { "${sonarqube::installdir}/${name}":
      ensure => link,
      target => "${sonarqube::home}/${name}",
  }
}
