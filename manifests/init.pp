# Copyright 2011 MaestroDev
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class sonar( $version, $user = "sonar", $group = "sonar", $service = "sonar",
  $installroot = "/usr/local", $home = "/var/local/sonar", $port = 9000,
  $download_url = "http://dist.sonar.codehaus.org",
  $arch = "", $ldap = {},
  $jdbc = {
    url => "jdbc:derby://localhost:1527/sonar;create=true",
    driver_class_name => "org.apache.derby.jdbc.ClientDriver",
    validation_query => "values(1)",
    username => "sonar",
    password => "sonar",
  },
  $log_folder = "/var/local/sonar/logs", $profile = false) {

  Exec { path => "/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/bin" }
  File { owner => $user, group => $group }

  # wget from https://github.com/maestrodev/puppet-wget
  include wget

  # calculate in what folder is the binary to use for this architecture
  $arch1 = $::kernel ? {
    "windows" => "windows",
    "sunos" => "solaris",
    "darwin" => "macosx",
    default  => "linux",
  }
  if $arch1 != "macosx" {
    $arch2 = $::architecture ? {
      "x86_64" => "x86-64",
      default  => "x86-32",
    }
  } else {
    $arch2 = $::architecture ? {
      "x86_64" => "universal-64",
      default  => "universal-32",
    }
  }
  $bin_folder = $arch ? { "" => "${arch1}-${arch2}", default => $arch }

  $installdir = "${installroot}/${service}"
  $tmpzip = "/usr/local/src/${service}-${version}.zip"
  $script = "${installdir}/bin/${bin_folder}/sonar.sh"

  # move folders susceptible to change from installation folder to /var/local/sonar and symlink
  define move_to_home() {
    exec { "mv ${sonar::installdir}/${name} ${sonar::home}":
      creates => "${sonar::home}/${name}",
    } ->
    file { "${sonar::installdir}/${name}":
      ensure => link,
      target => "${sonar::home}/${name}",
    }
  }

  user { "$user":
    ensure     => present,
    home       => $home,
    managehome => false,
  } ->
  group { "$group":
    ensure  => present,
  } ->
  wget::fetch { "download":
    source => "${download_url}/sonar-${version}.zip",
    destination => $tmpzip,
  } ->
  exec { "untar":
    command => "unzip ${tmpzip} -d ${installroot} && chown -R ${user}:${group} ${installroot}/sonar-${version}",
    creates => "${installroot}/sonar-${version}",
  } ->
  file { $installdir:
    ensure => link,
    target => "${installroot}/sonar-${version}",
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

  # we need to patch the init.d scripts until Sonar 2.12
  # https://github.com/SonarSource/sonar/pull/15
  patch { "initd":
    cwd => $installdir,
    patch => template("sonar/sonar-${version}.patch"),
  } ->

  # Sonar home
  file { $home:
    ensure => directory,
    mode => 0700,
  } ->
  move_to_home { "data": } ->
  move_to_home { "extras": } ->
  move_to_home { "extensions": } ->
  move_to_home { "logs": } ->

  # Sonar configuration files
  file { "${installdir}/conf/sonar.properties":
    content => template("sonar/sonar.properties.erb"),
    notify => Service[$service],
  } ->
  file { "${installdir}/conf/logback.xml":
    content => template("sonar/logback.xml.erb"),
    notify => Service[$service],
  } ->

  service { $service:
    name => $service,
    ensure => running,
    hasrestart => true,
    hasstatus => true,
    enable => true,
  }

}
