class sonar( $version = "2.10", $user = "sonar", $group = "sonar", $service = "sonar",
  $home = "/usr/local", $download_url = "http://dist.sonar.codehaus.org/sonar-$version.zip",
  $arch = "linux-x86-64" ) {

  Exec { path => "/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/bin" }
  File { owner => $user, group => $group }

	include wget
	#include sonar::patch # install patch prerequisites

  $tmpzip = "/usr/local/src/${service}-${version}.zip"
  $script = "${home}/${service}/bin/${arch}/sonar.sh"

	user { "$user":
    ensure     => present,
    home       => "$home/$user",
    managehome => false,
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
    target => "${home}/sonar-${version}",
  } ->
  exec { "run_as_user":
    command => "mv ${script} ${script}.bak && sed -e 's/#RUN_AS_USER=/RUN_AS_USER=${user}/' ${script}.bak > ${script}",
    unless  => "grep RUN_AS_USER=${user} ${script}",
  } ->
  file { $script:
    mode => 755,
  } ->
  file { "/etc/init.d/${service}":
    ensure  => link,
    target  => $script,
  } ->

  # we need to patch the init.d scripts until fixed in Sonar
  # https://github.com/SonarSource/sonar/pull/15
  patch { "initd" :
    cwd => "${home}/${service}",
    patch => template("sonar/sonar-${version}.patch"),
  } ->

  service { $service:
    name => $service,
    ensure => running,
    hasrestart => true,
    hasstatus => true,
    enable => true,
  }

}
