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
    let(:version) { '4.1.2' }

    it_should_behave_like :sonar

    context 'using LDAP' do
      let(:pp) { %Q(
        $ldap = {
          url          => 'ldap://myserver.mycompany.com',
          user_base_dn => 'ou=Users,dc=mycompany,dc=com',
        }

        class { 'sonarqube' :
          version => '#{version}',
          ldap    => $ldap,
        }
      ) }
      it { apply_manifest(pp, :catch_failures => true) }
      it { file("#{home}/extensions/plugins/sonar-ldap-plugin-1.4.jar").should be_file }

      it { file("#{installroot}/conf/sonar.properties").content.should match(%r{^ldap.url=ldap://myserver.mycompany.com}) }
    end
  end

  context 'when installing version 3' do
    let(:version) { '3.7.4' }

    before(:all) do
      on(hosts, "service sonar stop && rm -rf /etc/init.d/sonar* #{installroot}* #{home}*")
    end

    it_should_behave_like :sonar
  end

end
