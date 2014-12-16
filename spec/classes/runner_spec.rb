require 'spec_helper'

describe 'sonarqube::runner' do
  let(:facts) {{
    :operatingsystem => 'CentOS',
    :http_proxy => '',
  }}

  context 'when installing' do
    it { should create_class('sonarqube::runner::install') }
    it { should create_class('sonarqube::runner::config') }
  end
end
