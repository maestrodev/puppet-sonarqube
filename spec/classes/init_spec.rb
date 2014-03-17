require 'spec_helper'

SONAR_PROPERTIES = "/usr/local/sonar/conf/sonar.properties"

describe 'sonarqube' do

  context "when installing version 3", :compile do
    let(:params) {{ :version => '3.7.4' }}
    it { should contain_wget__fetch('download-sonar').with_source('http://dist.sonar.codehaus.org/sonar-3.7.4.zip') }
  end

  context "when installing version 4", :compile do
    let(:params) {{ :version => '4.1.2' }}
    it { should contain_wget__fetch('download-sonar').with_source('http://dist.sonar.codehaus.org/sonarqube-4.1.2.zip') }
  end

  context "when crowd configuration is supplied", :compile do
    let(:params) { { :crowd => {
      'application' => 'crowdapplication',
      'service_url' => 'crowdserviceurl',
      'password'    => 'crowdpassword',
    } } }

    it { should contain_sonarqube__plugin('sonar-crowd-plugin').with_ensure('present') }

    it { should contain_file(SONAR_PROPERTIES) }
    it 'should generate sonar.properties config for crowd' do
      content = subject.resource('file', SONAR_PROPERTIES).send(:parameters)[:content]
      content.should =~ %r[sonar\.authenticator\.class: org\.sonar\.plugins\.crowd\.CrowdAuthenticator]
      content.should =~ %r[crowd\.url: crowdserviceurl]
      content.should =~ %r[crowd\.application: crowdapplication]
      content.should =~ %r[crowd\.password: crowdpassword]
    end
  end

  context "when no crowd configuration is supplied", :compile do
    it { should contain_sonarqube__plugin('sonar-crowd-plugin').with_ensure('absent') }

    it { should contain_file(SONAR_PROPERTIES) }
    it 'should generate sonar.properties config without crowd' do
      content = subject.resource('file', SONAR_PROPERTIES).send(:parameters)[:content]
      content.should_not =~ %r[crowd]
    end
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
end
