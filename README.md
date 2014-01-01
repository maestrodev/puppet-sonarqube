Puppet-Sonar
============

**NOTE: MOVED TO [puppet-sonarqube](https://github.com/maestrodev/puppet-sonarqube) to support the new versions of SonarQube**

A puppet recipe to install Sonar


# Usage

    class { 'maven::maven' : } ->
    class { 'sonar' :
      version => '2.11',
    }

or

    $jdbc = {
      url               => 'jdbc:derby://localhost:1527/sonar;create=true',
      driver_class_name => 'org.apache.derby.jdbc.ClientDriver',
      validation_query  => 'values(1)',
      username          => 'sonar',
      password          => 'sonar',
    }

    class { 'maven::maven' : } ->
    class { 'sonar' :
      arch         => 'linux-x86-64',
      version      => '2.11',
      user         => 'sonar',
      group        => 'sonar',
      service      => 'sonar',
      installroot  => '/usr/local',
      home         => '/var/local/sonar',
      download_url => 'http://dist.sonar.codehaus.org',
      jdbc         => $jdbc,
      log_folder   => '/var/local/sonar/logs',
    }


## Sonar Plugins

The `sonar::plugin` defined type can also be used to install Sonar plugins, e.g.:

    sonar::plugin { 'sonar-twitter-plugin' :
      groupid    => 'org.codehaus.sonar-plugins',
      artifactid => 'sonar-twitter-plugin',
      version    => '0.1',
      notify     => Service['sonar'],
    }
    

### LDAP Plugin

The `sonar` class actually includes "built-in" support for the LDAP plugin to make it easier to use, e.g.:

    $ldap = {
      url          => 'ldap://myserver.mycompany.com',
      user_base_dn => 'ou=Users,dc=mycompany,dc=com',
    }

    class { 'sonar' :
      ldap => $ldap,
    }


# Module requirements

* maestrodev/wget
* maestrodev/maven
* puppetlabs/stdlib

# License

    Copyright 2011-2013 MaestroDev, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
