#
# Cookbook Name:: cloud_servers_vpc
# Recipe:: default
#
# Copyright 2010, Rackspace
#

package "rails-stack" do
  action :install
  version "2.3.8"
end

package "cloud-servers-vpc" do
  action :install
  version node[:cloud_servers_vpc][:version] if node[:cloud_servers_vpc][:version]
end

package "mysql-server" do
  action :install
end

service "mysqld" do
  supports :status => true, :restart => true, :reload => false
  action [ :enable, :start ]
end

service "httpd" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end

bash "create_update_db" do
  action :nothing
  cwd "/tmp"
  user "root"
  code <<-EOH
    cd #{node[:cloud_servers_vpc][:home]}
    RAILS_ENV=production rails-stack-ruby /usr/lib/rails-stack-gems/bin/rake db:create
    RAILS_ENV=production rails-stack-ruby /usr/lib/rails-stack-gems/bin/rake db:migrate
  EOH
  subscribes :run, resources(:package => "cloud-servers-vpc")
end

service "monit" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end

bash "stop_delayed_job" do
  action :nothing
  cwd "/tmp"
  user "root"
  code <<-EOH
	/usr/bin/cloud-servers-vpc-stop-dj || /bin/true
  EOH
  notifies :restart, resources("service[monit]", "service[httpd]")
  subscribes :run, resources(:package => "cloud-servers-vpc")
end

template "#{node[:cloud_servers_vpc][:home]}/config/environments/production.rb" do
  owner "cloud_servers_vpc"
  group "cloud_servers_vpc"
  mode "0644"
  source "production.rb.erb"
  notifies :run, resources(:bash => "stop_delayed_job")
end
