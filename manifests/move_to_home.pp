# copy folders susceptible to change from installation folder to /var/local/sonar and symlink
define sonar::move_to_home() {
  file { "${sonar::home}/${name}":
      ensure => directory,
  } ->

  file { "${sonar::installdir}/${name}":
      ensure => link,
      target => "${sonar::home}/${name}",
  }
}
