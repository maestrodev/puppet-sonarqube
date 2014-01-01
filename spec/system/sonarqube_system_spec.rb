require 'spec_helper_system'

describe 'sonarqube' do

  let(:installroot) { '/usr/local/sonar' }
  let(:home) { '/var/local/sonar' }

  before(:all) do
    [0,2].should include(puppet_apply(%Q(
      class { 'java': }
      class { 'maven::maven': }
     )).exit_code)
  end

  context 'installing with defaults' do
    let(:pp) { %Q(
      class { 'sonarqube' : }
    ) }
    it { [0,2].should include(puppet_apply(pp).exit_code) }

    it { file("#{installroot}/data").should be_linked_to("#{home}/data") }
    it { file("#{home}/data").should be_directory }

    describe file("/usr/local/sonar/conf/sonar.properties") do
      its(:content) { should_not match(/^ldap/) }
    end
  end

  context 'when using LDAP' do
    let(:pp) { %Q(
      $ldap = {
        url          => 'ldap://myserver.mycompany.com',
        user_base_dn => 'ou=Users,dc=mycompany,dc=com',
      }

      class { 'sonarqube' :
        ldap => $ldap,
      }
    ) }
    it { [0,2].should include(puppet_apply(pp).exit_code) }
    it { file("#{home}/extensions/plugins/sonar-ldap-plugin-1.3.jar").should be_file }

    describe file("/usr/local/sonar/conf/sonar.properties") do
      its(:content) { should match(%r{^ldap.url=ldap://myserver.mycompany.com}) }
    end
  end

end
