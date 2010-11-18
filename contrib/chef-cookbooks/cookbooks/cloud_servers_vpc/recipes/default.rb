#
# Cookbook Name:: cloud_servers_vpc
# Recipe:: default
#
# Copyright 2010, Rackspace
#

include_recipe "ruby_enterprise"
include_recipe "apache2"

["mysql-server","mysql-devel"].each do |pkg|
  package pkg do
    action :install
  end
end

service "mysqld" do
  supports :status => true, :restart => true, :reload => false
  action [ :enable, :start ]
end

[
  ['rake','0.8.7'],
  ['rails','2.3.8'],
  ['mysql','2.8.1'],
  ['json','1.4.3'],
  ['daemons','1.1.0']
].each do |gem_version|

  ree_gem gem_version[0] do
    version gem_version[1]
  end

end

user "cloud_servers_vpc" do
  comment "Cloud Servers VPC"
  system true
  shell "/bin/false"
end

version_check_file="#{node[:cloud_servers_vpc][:home]}/version_#{node[:cloud_servers_vpc][:version]}"
bash "download_and_extract" do
  action :run
  cwd "/tmp"
  code <<-EOH
    mkdir -p #{node[:cloud_servers_vpc][:home]}
    cd #{node[:cloud_servers_vpc][:home]}
    wget --no-check-certificate https://github.com/rackspace/cloud_servers_vpc/tarball/#{node[:cloud_servers_vpc][:version]} -O - | tar -xz
    mv rackspace-*/* .
    rm -Rf rackspace*
    cd /opt && chown cloud_servers_vpc:cloud_servers_vpc -R cloud-servers-vpc
    touch #{version_check_file}
  EOH
  not_if do File.exists?(version_check_file) end
end

["/opt/cloud-servers-vpc/tmp/pids", "/opt/cloud-servers-vpc/tmp/ssh_keys"].each do |tmp_dir|
  directory tmp_dir do
    owner "cloud_servers_vpc"
    group "cloud_servers_vpc"
    mode "0755"
    action :create
    recursive true
  end
end

bash "create_update_db" do
  action :nothing
  cwd "/tmp"
  user "root"
  code <<-EOH
    cd #{node[:cloud_servers_vpc][:home]}
    RAILS_ENV=production /opt/ruby-enterprise/bin/ruby /opt/ruby-enterprise/bin/rake db:create
    RAILS_ENV=production /opt/ruby-enterprise/bin/ruby /opt/ruby-enterprise/bin/rake db:migrate
  EOH
  subscribes :run, resources("bash[download_and_extract]")
end

cookbook_file "/etc/pki/tls/private/ca.key" do
  source "ca.key"
  mode 0600
end

cookbook_file "/etc/pki/tls/certs/ca.crt" do
  source "ca.crt"
  mode 0600
end

package "monit"

template "/etc/monit.d/cloud_servers_vpc.monit" do
  mode "0644"
  source "cloud_servers_vpc.monit.erb"
end

service "monit" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
  subscribes :restart, resources("template[/etc/monit.d/cloud_servers_vpc.monit]")
end

bash "stop_delayed_job" do
  action :nothing
  cwd "/tmp"
  user "root"
  code <<-EOH
      /usr/bin/cloud-servers-vpc-stop-dj || /bin/true
  EOH
  notifies :restart, resources("service[monit]", "service[apache2]")
  subscribes :run, resources("bash[download_and_extract]")
end

template "#{node[:cloud_servers_vpc][:home]}/config/environments/production.rb" do
  owner "cloud_servers_vpc"
  group "cloud_servers_vpc"
  mode "0644"
  source "production.rb.erb"
  notifies :run, resources(:bash => "stop_delayed_job")
end

web_app "cloud_servers_vpc" do
  docroot "/opt/cloud-servers-vpc/public"
  server_name "vpc.#{node[:domain]}"
  server_aliases [ "vpc", node[:hostname] ]
  rails_env "production"
end

execute "touch_cron_d" do
  command "touch /etc/cron.d"
  action :nothing
end

template "/etc/cron.d/cloud_servers_vpc" do
  mode "0644"
  source "cloud_servers_vpc.cron.erb"
  notifies :run, resources("execute[touch_cron_d]")
end
