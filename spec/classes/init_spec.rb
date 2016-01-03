require 'spec_helper'

describe 'sonarqube' do

  let(:sonar_properties) { '/usr/local/sonar/conf/sonar.properties' }

  context "when installing version 4", :compile do
    let(:params) {{ :version => '4.5.5' }}
    it { should contain_wget__fetch('download-sonar').with_source('https://sonarsource.bintray.com/Distribution/sonarqube/sonarqube-4.5.5.zip') }
  end

  context "when crowd configuration is supplied", :compile do
    let(:params) { { :crowd => {
      'application' => 'crowdapplication',
      'service_url' => 'crowdserviceurl',
      'password'    => 'crowdpassword',
    } } }

    it 'should generate sonar.properties config for crowd' do
      should contain_file(sonar_properties).with_content(%r[sonar\.authenticator\.class: org\.sonar\.plugins\.crowd\.CrowdAuthenticator])
      should contain_file(sonar_properties).with_content(%r[crowd\.url: crowdserviceurl])
      should contain_file(sonar_properties).with_content(%r[crowd\.application: crowdapplication])
      should contain_file(sonar_properties).with_content(%r[crowd\.password: crowdpassword])
    end
  end

  context "when no crowd configuration is supplied", :compile do
    it { should contain_file(sonar_properties).without_content("crowd") }
  end

  context "when unzip package is not defined", :compile do
    it { should contain_package('unzip').with_ensure('present') }
  end

  context "when unzip package is already defined", :compile do
    let(:pre_condition) { %Q[
      package { 'unzip': ensure => installed }
    ] }

    it { should contain_package('unzip').with_ensure('installed') }
  end

  context "when ldap local users configuration is supplied", :compile do
    let(:params) { { :ldap => {
      'url'          => 'ldap://myserver.mycompany.com',
      'user_base_dn' => 'ou=Users,dc=mycompany,dc=com',
      'local_users'  => 'foo',
    } } }

    it { should contain_file(sonar_properties).with_content(/sonar.security.localUsers=foo/) }
    it { should contain_file(sonar_properties).with_content(/sonar.security.realm=LDAP/) }
    it { should contain_file(sonar_properties).with_content(/ldap.url=ldap:\/\/myserver.mycompany.com/) }
    it { should contain_file(sonar_properties).with_content(/ldap.user.baseDn: ou=Users,dc=mycompany,dc=com/) }
  end

  context "when ldap local users configuration is supplied as array", :compile do
    let(:params) { { :ldap => {
      'url'          => 'ldap://myserver.mycompany.com',
      'user_base_dn' => 'ou=Users,dc=mycompany,dc=com',
      'local_users' => ['foo','bar'],
    } } }

    it { should contain_file(sonar_properties).with_content(/sonar.security.localUsers=foo,bar/) }
    it { should contain_file(sonar_properties).with_content(/sonar.security.realm=LDAP/) }
    it { should contain_file(sonar_properties).with_content(/ldap.url=ldap:\/\/myserver.mycompany.com/) }
    it { should contain_file(sonar_properties).with_content(/ldap.user.baseDn: ou=Users,dc=mycompany,dc=com/) }
  end

  context "when no ldap local users configuration is supplied", :compile do
    let(:params) { { :ldap => {
      'url'          => 'ldap://myserver.mycompany.com',
      'user_base_dn' => 'ou=Users,dc=mycompany,dc=com',
    } } }
    it { should contain_file(sonar_properties).without_content(/sonar.security.localUsers/) }
    it { should contain_file(sonar_properties).with_content(/sonar.security.realm=LDAP/) }
    it { should contain_file(sonar_properties).with_content(/ldap.url=ldap:\/\/myserver.mycompany.com/) }
    it { should contain_file(sonar_properties).with_content(/ldap.user.baseDn: ou=Users,dc=mycompany,dc=com/) }
  end

  context "when no ldap configuration is supplied", :compile do
    it { should contain_file(sonar_properties).without_content(/sonar.security/) }
    it { should contain_file(sonar_properties).without_content(/ldap./) }
  end
end
