#
# Cookbook Name:: monit-ng
# Recipe:: config
#

monit = node['monit']
config = monit['config']

# Exists in older Debian/Ubuntu platforms
# and disables monit starting by default
# despite being enabled in appropriate run-levels
template '/etc/default/monit' do
  source 'monit.default.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    :platform         => node['platform'],
    :platform_version => node['platform_version'],
  )
  only_if { platform_family?('debian') && ::File.exist?('/etc/default/monit') }
end

directory monit['conf_dir'] do
  owner 'root'
  group 'root'
  mode '0600'
  recursive true
  action :create
end

template monit['conf_file'] do
  source 'monit.conf.erb'
  owner 'root'
  group 'root'
  mode '0600'
  variables(
    :poll_freq => config['poll_freq'],
    :start_delay => config['start_delay'],
    :log_file => config['log_file'],
    :id_file => config['id_file'],
    :state_file => config['state_file'],
    :mail_servers => config['mail_servers'],
    :subscribers => config['subscribers'],
    :eventqueue_dir => config['eventqueue_dir'],
    :eventqueue_slots => config['eventqueue_slots'],
    :listen => config['listen'],
    :port => config['port'],
    :allow => config['allow'],
    :mail_from => config['mail_from'],
    :mail_subject => config['mail_subject'],
    :mail_msg => config['mail_message'],
    :mmonit_url => config['mmonit_url'],
    :conf_dir => monit['conf_dir'],
  )
  notifies :restart, 'service[monit]', :immediately
end

service 'monit' do
  case monit['install_method']
  when 'source'
    unless node.platform_family?('rhel') && node.platform_version.to_f >= 7.0
      status_command '/etc/init.d/monit status | grep -q uptime'
      supports :reload => true, :status => true, :restart => true
    end
  when 'repo'
    if platform_family?('debian') && ::File.exist?('/etc/default/monit')
      subscribes :restart, 'template[/etc/default/monit]', :immediately
    else
      supports :reload => true, :status => true, :restart => true
    end
  end
  action [:enable, :start]
  subscribes :restart, 'template[monit-init]', :delayed
end
