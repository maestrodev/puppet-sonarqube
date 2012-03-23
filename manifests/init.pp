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

class sonar (
  $version = '2.13.1',
  $user = 'sonar',
  $group = 'sonar',
  $user_system = true,
  $service = 'sonar', $installroot = '/usr/local', $home = '/var/local/sonar',
  $port = 9000, $download_url = 'http://dist.sonar.codehaus.org', 
  $context_path = '/', $arch = '', $ldap = {},
  $jdbc = {
    url               => 'jdbc:derby://localhost:1527/sonar;create=true',
    driver_class_name => 'org.apache.derby.jdbc.ClientDriver',
    validation_query  => 'values(1)',
    username          => 'sonar',
    password          => 'sonar',
  },
  $log_folder = '/var/local/sonar/logs', $profile = false) {

  Exec {
    path => '/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/bin'
  }
  File {
    owner => $user,
    group => $group
  }

  # wget from https://github.com/maestrodev/puppet-wget
  include wget

  # calculate in what folder is the binary to use for this architecture
  $arch1 = $::kernel ? {
    'windows' => 'windows',
    'sunos'   => 'solaris',
    'darwin'  => 'macosx',
    default   => 'linux',
  }
  if $arch1 != 'macosx' {
    $arch2 = $::architecture ? {
      'x86_64' => 'x86-64',
      default  => 'x86-32',
    }
  } else {
    $arch2 = $::architecture ? {
      'x86_64' => 'universal-64',
      default  => 'universal-32',
    }
  }
  $bin_folder = $arch ? { '' => "${arch1}-${arch2}", default => $arch }

  $installdir = "${installroot}/${service}"
  $tmpzip = "/usr/local/src/${service}-${version}.zip"
  $script = "${installdir}/bin/${bin_folder}/sonar.sh"

  user { $user:
    ensure     => present,
    home       => $home,
    managehome => false,
    system     => $user_system,
  } ->
  group { $group:
    ensure  => present,
    system  => $user_system,
  } ->
  wget::fetch {
    'download-sonar':
      source      => "${download_url}/sonar-${version}.zip",
      destination => $tmpzip,
  } ->


  # ===== Create folder structure =====
  # so uncompressing new sonar versions at update time use the previous sonar home,
  # installing new extensions and plugins over the old ones, reusing the db,...

  # Sonar home
  file { $home:
    ensure => directory,
    mode   => '0700',
  } ->
  file { "${installroot}/sonar-${version}":
    ensure => directory,
  } ->
  file { $installdir:
    ensure => link,
    target => "${installroot}/sonar-${version}",
  } ->
  sonar::move_to_home { 'data': } ->
  sonar::move_to_home { 'extras': } ->
  sonar::move_to_home { 'extensions': } ->
  sonar::move_to_home { 'logs': } ->

  # ===== Install Sonar =====

  exec { 'untar':
    command => "unzip -o ${tmpzip} -d ${installroot} && chown -R ${user}:${group} ${installroot}/sonar-${version}",
    creates => "${installroot}/sonar-${version}/bin",
  } ->
  file { $script:
    mode    => '0755',
    content => template("sonar/sonar.sh.erb"),
  }
  file { "/etc/init.d/${service}":
    ensure  => link,
    target  => $script,
  } ->

  # Sonar configuration files
  file { "${installdir}/conf/sonar.properties":
    content => template('sonar/sonar.properties.erb'),
    require => Exec['untar'],
    notify  => Service[$service],
  } ->
  # The plugins directory. Useful to later reference it from the plugin definition
  file { "${home}/extensions/plugins":
    ensure => directory,
  } ->

  sonar::plugin { 'sonar-ldap-plugin' :
    ensure     => empty($ldap) ? {true => absent, false => present},
    artifactid => 'sonar-ldap-plugin',
    version    => '1.0',
    notify     => Service[$service],
  } ->

  service { $service:
    ensure     => running,
    name       => $service,
    hasrestart => true,
    hasstatus  => true,
    enable     => true,
    require    => File["/etc/init.d/${service}"],
  }

  if $version in ['2.5', '2.6', '2.10', '2.11'] {
    # set the right log location, not needed in Sonar 2.12+
    file { "${installdir}/conf/logback.xml":
      content => template('sonar/logback.xml.erb'),
      require => Exec['untar'],
      notify  => Service[$service],
    }
  }

}
