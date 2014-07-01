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
class sonarqube (
  $version = '4.1.2',
  $user = 'sonar',
  $group = 'sonar',
  $user_system = true,
  $service = 'sonar',
  $installroot = '/usr/local',
  $home = undef,
  $host = undef,
  $port = 9000,
  $portAjp = -1,
  $download_url = 'http://dist.sonar.codehaus.org',
  $context_path = '/',
  $arch = $sonarqube::params::arch,
  $ldap = {}, $crowd = {},
  $jdbc = {
    url               => 'jdbc:h2:tcp://localhost:9092/sonar',
    username          => 'sonar',
    password          => 'sonar',
  },
  $log_folder = '/var/local/sonar/logs',
  $updatecenter = 'true',
  $http_proxy = {},
  $profile = false) inherits sonarqube::params {

  Exec {
    path => '/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/bin'
  }
  File {
    owner => $user,
    group => $group
  }

  # wget from https://github.com/maestrodev/puppet-wget
  include wget

  if versioncmp($version, '4.0') < 0 {
    $package_name = 'sonar'
  }
  else {
    $package_name = 'sonarqube'
  }

  if $home != undef {
    $real_home = $home
  }
  else {
    $real_home = "/var/local/sonar"
  }
  Sonarqube::Move_to_home {
    home => $real_home,
  }

  $extensions_dir = "${real_home}/extensions"
  $plugin_dir = "${extensions_dir}/plugins"

  $installdir = "${installroot}/${service}"
  $tmpzip = "/usr/local/src/${package_name}-${version}.zip"
  $script = "${installdir}/bin/${arch}/sonar.sh"

  if ! defined(Package[unzip]) {
    package { 'unzip':
      ensure => present,
      before => Exec[untar]
    }
  }

  user { $user:
    ensure     => present,
    home       => $real_home,
    managehome => false,
    system     => $user_system,
  } ->
  group { $group:
    ensure  => present,
    system  => $user_system,
  } ->
  wget::fetch {
    "download-sonar":
      source      => "${download_url}/${package_name}-${version}.zip",
      destination => $tmpzip,
  } ->


  # ===== Create folder structure =====
  # so uncompressing new sonar versions at update time use the previous sonar home,
  # installing new extensions and plugins over the old ones, reusing the db,...

  # Sonar home
  file { $real_home:
    ensure => directory,
    mode   => '0700',
  } ->
  file { "${installroot}/${package_name}-${version}":
    ensure => directory,
  } ->
  file { $installdir:
    ensure => link,
    target => "${installroot}/${package_name}-${version}",
  } ->
  sonarqube::move_to_home { 'data': } ->
  sonarqube::move_to_home { 'extras': } ->
  sonarqube::move_to_home { 'extensions': } ->
  sonarqube::move_to_home { 'logs': } ->

  # ===== Install Sonar =====

  exec { 'untar':
    command => "unzip -o ${tmpzip} -d ${installroot} && chown -R ${user}:${group} ${installroot}/${package_name}-${version} && chown -R ${user}:${group} ${real_home}",
    creates => "${installroot}/${package_name}-${version}/bin",
  } ->
  file { $script:
    mode    => '0755',
    content => template('sonarqube/sonar.sh.erb'),
  } ->
  file { "/etc/init.d/${service}":
    ensure  => link,
    target  => $script,
  } ->

  # Sonar configuration files
  file { "${installdir}/conf/sonar.properties":
    content => template('sonarqube/sonar.properties.erb'),
    require => Exec['untar'],
    notify  => Service['sonarqube'],
    mode    => '0600'
  }

  # The plugins directory. Useful to later reference it from the plugin definition
  file { $plugin_dir:
    ensure => directory,
  }

  # For convenience, provide "built-in" support for the Sonar LDAP plugin.
  sonarqube::plugin { 'sonar-ldap-plugin' :
    ensure     => empty($ldap) ? {true => absent, false => present},
    artifactid => 'sonar-ldap-plugin',
    version    => '1.4',
  }

  sonarqube::plugin { 'sonar-crowd-plugin' :
    ensure     => empty($crowd) ? {true => absent, false => present},
    artifactid => 'sonar-crowd-plugin',
    version    => '1.0',
  }

  service { 'sonarqube':
    ensure     => running,
    name       => $service,
    hasrestart => true,
    hasstatus  => true,
    enable     => true,
    require    => File["/etc/init.d/${service}"],
  }
}
