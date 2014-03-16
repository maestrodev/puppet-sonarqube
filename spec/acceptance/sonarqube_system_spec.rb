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
    it { file("#{installroot}/data").should be_linked_to("#{home}/data") }
    it { file("#{home}/data").should be_directory }

    describe file("/usr/local/sonar/conf/sonar.properties") do
      its(:content) { should_not match(/^ldap/) }
    end
    describe service('sonar') do
      it { should be_enabled }
      it { should be_running }
    end
  end

  context 'when installing version 3' do
    let(:version) { '3.7.4' }
    let(:pp) { %Q(
      class { 'sonarqube':
        version => '#{version}'
      }
    ) }
    it { apply_manifest(pp, :catch_failures => true) }
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
      it { file("#{home}/extensions/plugins/sonar-ldap-plugin-1.3.jar").should be_file }

      describe file("/usr/local/sonar/conf/sonar.properties") do
        its(:content) { should match(%r{^ldap.url=ldap://myserver.mycompany.com}) }
      end
    end
  end

  context 'when installing version 4' do
    let(:version) { '4.1.2' }
    let(:pp) { %Q(
      class { 'sonarqube':
        version => '#{version}'
      }
    ) }

    before { pending }

    it { apply_manifest(pp, :catch_failures => true) }
    it_should_behave_like :sonar
  end

end
