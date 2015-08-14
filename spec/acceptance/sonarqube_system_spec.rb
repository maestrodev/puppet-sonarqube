require 'spec_helper_acceptance'

describe 'sonarqube' do

  let(:installroot) { '/usr/local/sonar' }
  let(:home) { '/var/local/sonar' }

  before(:all) do
    apply_manifest(%Q(
      class { 'java': }
      class { 'maven::maven': }
    ), :catch_failures => true)
  end

  shared_examples :sonar do
    let(:pp) { %Q(
      class { 'sonarqube':
        version => '#{version}'
      }
    ) }
    it { apply_manifest(pp, :catch_failures => true) }

    it { file("#{installroot}/data").should be_linked_to("#{home}/data") }
    it { file("#{home}/data").should be_directory }
    it { file("#{installroot}/conf/sonar.properties").content.should_not match(/^ldap/) }

    describe service('sonar') do
      it { should be_enabled }
      it { should be_running }
    end
  end

  context 'when installing version 4' do
    let(:version) { '4.5.5' }

    it_should_behave_like :sonar

    context 'using LDAP' do
      let(:pp) { %Q(
        $ldap = {
          url          => 'ldap://myserver.mycompany.com',
          user_base_dn => 'ou=Users,dc=mycompany,dc=com',
          local_users  => ['foo', 'bar'],
        }

        class { 'sonarqube' :
          version => '#{version}',
          ldap    => $ldap,
        }
      ) }
      it { apply_manifest(pp, :catch_failures => true) }
      it { file("#{home}/extensions/plugins/sonar-ldap-plugin-1.4.jar").should be_file }

      it { file("#{installroot}/conf/sonar.properties").content.should match(%r{^ldap.url=ldap://myserver.mycompany.com}) }

      it { file("#{installroot}/conf/sonar.properties").content.should match(%r{^sonar.security.localUsers=foo,bar}) }
    end
  end

end
