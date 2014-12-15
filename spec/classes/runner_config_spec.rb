require 'spec_helper'

describe 'sonarqube::runner::config' do
  let(:params) {{
    :package_name => 'sonar-runner',
    :version => '2.4',
    :installroot => '/usr/local',
    :jdbc => {
      'url'      => 'jdbc:h2:tcp://localhost:9092/sonar',
      'username' => 'sonar',
      'password' => 'sonar',
    },
  }}

  context "check properties file" do
    it { should contain_file('/usr/local/sonar-runner-2.4/conf/sonar-runner.properties') }
  end
end
