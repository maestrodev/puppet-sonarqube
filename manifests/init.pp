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

class sonar( $version = "2.10", $user = "sonar", $group = "sonar", $service = "sonar",
  $install_dir = "/usr/local", $home = "/var/${service}",
  $download_url = "http://dist.sonar.codehaus.org/sonar-$version.zip",
  $arch = "linux-x86-64" ) {

  Exec { path => "/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/bin" }
  File { owner => $user, group => $group }

  # wget from https://github.com/maestrodev/puppet-wget
  include wget

  $tmpzip = "/usr/local/src/${service}-${version}.zip"
  $script = "${install_dir}/${service}/bin/${arch}/sonar.sh"

  user { "$user":
    ensure     => present,
    home       => $home,
    managehome => false,
  } ->
  group { "$group":
    ensure  => present,
  } ->
  wget::fetch { "download":
    source => $download_url,
    destination => $tmpzip,
    timeout => 60,
  } ->
  exec { "untar":
    command => "unzip ${tmpzip} -d ${install_dir} && chown -R ${user}:${group} ${install_dir}/sonar-${version}",
    creates => "${install_dir}/sonar-${version}",
  } ->
  file { "${install_dir}/${service}":
    ensure => link,
    target => "${install_dir}/sonar-${version}",
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
    cwd => "${install_dir}/${service}",
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
