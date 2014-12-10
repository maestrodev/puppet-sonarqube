class sonarqube::runner::config inherits sonarqube::runner {
  # Sonar Runner configuration file
  file { "${installroot}/${package_name}-${version}/conf/sonar-runner.properties":
    content => template('sonarqube/sonar-runner.properties.erb'),
    require => Exec['untar'],
  }
}
