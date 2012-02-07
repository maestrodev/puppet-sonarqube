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

class sonar( $version, $user = "sonar", $group = "sonar", $user_system = true, 
  $service = "sonar", $installroot = "/usr/local", $home = "/var/local/sonar", 
  $port = 9000, $download_url = "http://dist.sonar.codehaus.org",
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

  # copy folders susceptible to change from installation folder to /var/local/sonar and symlink
  define move_to_home() {
    file { "${sonar::home}/${name}":
      ensure => directory,
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
    system     => $user_system,
  } ->
  group { "$group":
    ensure  => present,
    system  => $user_system,
  } ->
  wget::fetch { "download":
    source => "${download_url}/sonar-${version}.zip",
    destination => $tmpzip,
  } ->


  # ===== Create folder structure =====
  # so uncompressing new sonar versions at update time use the previous sonar home,
  # installing new extensions and plugins over the old ones, reusing the db,...

  # Sonar home
  file { $home:
    ensure => directory,
    mode => 0700,
  } ->
  file { "${installroot}/sonar-${version}":
    ensure => directory,
  } ->
  file { $installdir:
    ensure => link,
    target => "${installroot}/sonar-${version}",
  } ->
  move_to_home { "data": } ->
  move_to_home { "extras": } ->
  move_to_home { "extensions": } ->
  move_to_home { "logs": } ->


  # ===== Install Sonar =====

  exec { "untar":
    command => "unzip -o ${tmpzip} -d ${installroot} && chown -R ${user}:${group} ${installroot}/sonar-${version}",
    creates => "${installroot}/sonar-${version}/bin",
  } ->
  exec { "run_as_user":
    command => "mv -f ${script} ${script}.bak && sed -e 's/#RUN_AS_USER=/RUN_AS_USER=${user}/' ${script}.bak > ${script}",
    unless  => "grep RUN_AS_USER=${user} ${script}",
  } ->
  exec { "pid_dir":
    command => "mv -f ${script} ${script}.bak && sed -e 's@PIDDIR=\"\\.\"@PIDDIR=\"${sonar::home}/logs\"@' ${script}.bak > ${script}",
    unless  => "grep PIDDIR=\\\"${sonar::home}/logs\\\" ${script}",
  } ->
  file { $script:
    mode => 755,
    require => Exec["run_as_user"], # to override puppet autorequirement
  } ->
  file { "/etc/init.d/${service}":
    ensure  => link,
    target  => $script,
  } ->

  # Sonar configuration files
  file { "${installdir}/conf/sonar.properties":
    content => template("sonar/sonar.properties.erb"),
    require => Exec["untar"],
    notify => Service[$service],
  } ->
  # The plugins directory. Useful to later reference it from the plugin definition
  file { "${home}/extensions/plugins":
    ensure => directory,
  } ->

  plugin { "sonar-ldap-plugin" :
    artifactid => "sonar-ldap-plugin",
    version => "1.0",
    ensure => empty($ldap) ? {true => absent, false => present},
    notify => Service[$service],
  } ->

  service { $service:
    name => $service,
    ensure => running,
    hasrestart => true,
    hasstatus => true,
    enable => true,
  }

  # we need to patch the init.d scripts until Sonar 2.12
  # https://github.com/SonarSource/sonar/pull/15
  if $version in ["2.5", "2.6", "2.10", "2.11"] {
    patch { "initd":
      cwd => $installdir,
      patch => template("sonar/sonar-${version}.patch"),
      require => Exec["untar"],
      before => Service[$service],
    }
    # set the right log location, not needed in Sonar 2.12+
    file { "${installdir}/conf/logback.xml":
      content => template("sonar/logback.xml.erb"),
      require => Exec["untar"],
      notify  => Service[$service],
    }
  }

}
