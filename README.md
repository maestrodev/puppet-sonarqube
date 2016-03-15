Puppet-SonarQube
================

[![Build Status](https://travis-ci.org/maestrodev/puppet-sonarqube.svg?branch=master)](https://travis-ci.org/maestrodev/puppet-sonarqube)
[![Puppet Forge](https://img.shields.io/puppetforge/v/maestrodev/sonarqube.svg)](https://forge.puppetlabs.com/maestrodev/sonarqube)
[![Puppet Forge](https://img.shields.io/puppetforge/f/maestrodev/sonarqube.svg)](https://forge.puppetlabs.com/maestrodev/sonarqube)
[![Quality Gate](https://nemo.sonarqube.org/api/badges/gate?key=puppet-sonarqube)](https://nemo.sonarqube.org/dashboard/index/puppet-sonarqube)


A puppet recipe to install SonarQube (former Sonar)


# Usage

    class { 'java': }
    class { 'sonarqube':
      version => '5.1',
    }

or

    $jdbc = {
      url      => 'jdbc:h2:tcp://localhost:9092/sonar',
      username => 'sonar',
      password => 'sonar',
    }

    class { 'sonarqube':
      arch          => 'linux-x86-64',
      version       => '5.1,
      user          => 'sonar',
      group         => 'sonar',
      service       => 'sonar',
      installroot   => '/usr/local',
      home          => '/var/local/sonar',
      download_url  => 'https://sonarsource.bintray.com/Distribution/sonarqube'
      jdbc          => $jdbc,
      web_java_opts => '-Xmx1024m',
      log_folder    => '/var/local/sonar/logs',
      updatecenter  => 'true',
      http_proxy    => {
      	host        => 'proxy.example.com',
      	port        => '8080',
      	ntlm_domain => '',
      	user        => '',
      	password    => '',
      }
    }

## SonarQube Plugins

The `sonarqube::plugin` defined type can be used to install SonarQube plugins. Note that Maven is required to download the plugins then.

    class { 'java': }
    class { 'maven::maven': }
    ->
    class { 'sonarqube': }
    
    sonarqube::plugin { 'sonar-javascript-plugin':
      groupid    => 'org.sonarsource.javascript',
      artifactid => 'sonar-javascript-plugin',
      version    => '2.10',
      notify     => Service['sonar'],
    }
    

## Security Configuration

The `sonarqube` class provides an easy way to configure security with LDAP, Crowd or PAM. Here's an example with LDAP:

    $ldap = {
      url          => 'ldap://myserver.mycompany.com',
      user_base_dn => 'ou=Users,dc=mycompany,dc=com',
      local_users  => ['foo', 'bar'],
    }

    class { 'java': }
    class { 'maven::maven': }
    ->
    class { 'sonarqube':
      ldap => $ldap,
    }

    # Do not forget to add the SonarQube LDAP plugin that is not provided out of the box.
    # Same thing with Crowd or PAM.
    sonarqube::plugin { 'sonar-ldap-plugin':
      groupid    => 'org.sonarsource.ldap',
      artifactid => 'sonar-ldap-plugin',
      version    => '1.5.1',
      notify     => Service['sonar'],
    }


# Module Requirements

* maestrodev/wget
* maestrodev/maven (only if additional SonarQube plugins are needed to be installed)
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
