# frozen_string_literal: true

include_recipe 'kibana'

if node['kibana']['install_method'] == 'release'
  ark 'kibana' do
    url node['kibana']['kibana6_url']
    version node['kibana']['kibana6_version']
    checksum node['kibana']['kibana6_checksum']
    path node['kibana']['base_dir']
    home_dir File.join(node['kibana']['base_dir'], 'current')
    owner node['kibana']['user']
  end
  config_path = 'current/config/kibana.yml'
elsif node['kibana']['install_method'] == 'package'
  node.default['kibana']['service']['bin_path'] = 'bin'
  if platform_family? 'debian'
    apt_repository 'kibana' do
      uri node['kibana']['repository_url']
      distribution ''
      components %w[stable main]
      key node['kibana']['repository_key']
    end
  else
    Chef::Log.warn "I do not support your platform: #{node['platform_family']}"
  end

  package 'kibana'
  config_path = 'config/kibana.yml'
else
  Chef::Application.fatal!("Since Kibana version 4, install method can only be only 'release' or 'package'")
end

# Install service
include_recipe 'kibana::_service'

# Apply config template
template File.join(node['kibana']['base_dir'], config_path) do
  cookbook node['kibana']['config']['cookbook']
  source 'kibana6.yml.erb'
  owner node['kibana']['user']
  group node['kibana']['group']
  mode '0644'
  variables(
    bind:           node['kibana']['interface'],
    port:           node['kibana']['port'],
    es_user:        node['kibana']['elasticsearch']['user'] || 'kibana',
    es_pass:        node['kibana']['elasticsearch']['password'] || 'kibana',
    es_host:        node['kibana']['elasticsearch']['hosts'].first,
    es_port:        node['kibana']['elasticsearch']['port'],
    index:          node['kibana']['index'],
    defaultapp:     node['kibana']['defaultapp'],
    logging_option: node['kibana']['logging_option'],
    extra_config:   node['kibana']['extra_config']
  )
  notifies :restart, 'service[kibana]'
end
