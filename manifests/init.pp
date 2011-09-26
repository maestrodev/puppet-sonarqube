Exec { path => "/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/bin" }

class sonar( $version = "2.10", $user = "sonar", $group = "sonar", $service = "sonar",
  $home = "/usr/local", $download_url = "http://dist.sonar.codehaus.org/sonar-$version.zip",
  $arch = "linux-x86-64" ) {

	include wget

  $tmpzip = "/usr/local/src/${service}-${version}.zip"

	user { "$user":
    ensure     => present,
    home       => "$home/$user",
    managehome => false,
    shell      => "/bin/false",
  } ->
  group { "$group":
    ensure  => present,
    require => User["$user"],
  } ->
  wget::fetch { "download":
    source => $download_url,
    destination => $tmpzip,
    timeout => 60,
  } ->
  exec { "untar":
    command => "unzip ${tmpzip} -d ${home} && chown -R ${user}:${group} ${home}/sonar-${version}",
    creates => "${home}/sonar-${version}",
  } ->
  file { "${home}/${service}":
    ensure => link,
    target => "$home/sonar-$version",
  } ->
  # TODO set RUN_AS_USER=${user}
  file { "${home}/${service}/bin/${service}":
    ensure  => link,
    target  => "${home}/${service}/bin/${arch}/sonar.sh",
  } ->
  file { "/etc/init.d/${service}":
    ensure  => link,
    target  => "${home}/${service}/bin/${service}",
  } ->
  service { $service:
    name => $service,
    ensure => running,
    hasrestart => true,
    hasstatus => true,
    enable => true,
  }
}
