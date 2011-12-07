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

# Class: plugin
#
# A puppet definition for Sonar plugin installation
#
define plugin($groupid = "org.codehaus.sonar-plugins", $artifactid, $version, $ensure = present) {

  $plugin = "${sonar::home}/extensions/plugins/${artifactid}-${version}.jar"

  if $ensure == present {
    maven { $plugin:
      groupid => $groupid,
      artifactid => $artifactid,
      version => $version,
      before => File[$plugin],
    }
  }
  file { $plugin:
    ensure => $ensure,
  }
}
