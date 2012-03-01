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

# Definition: plugin
#
# A puppet definition for Sonar plugin installation
#
define sonar::plugin(
  $artifactid, $version,
  $groupid = 'org.codehaus.sonar-plugins', $ensure = present) {

  $plugin_dir  = "${sonar::home}/extensions/plugins"
  $plugin_name = "${artifactid}-${version}.jar"
  $plugin      = "${plugin_dir}/${plugin_name}"

  # Install plugin
  if $ensure == present {
    # copy to a temp file as Maven can run as a different user and not have rights to copy to
    # sonar plugin folder
    maven { "/tmp/${plugin_name}":
      groupid    => $groupid,
      artifactid => $artifactid,
      version    => $version,
      before     => File[$plugin],
      require    => File[$plugin_dir],
    }
    file { $plugin:
      ensure => $ensure,
      source => "/tmp/${plugin_name}",
      owner  => $sonar::user,
      group  => $sonar::group,
    }
  } else {
    # Uninstall plugin if absent
    file { $plugin:
      ensure => $ensure,
    }
  }
}
