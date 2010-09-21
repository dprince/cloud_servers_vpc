%define debug_package %{nil}

Name: cloud-servers-vpc
Version: 1.6.0
Release: 1
Summary: Rackspace Cloud Servers Virtual Private Cloud application
Packager: Dan Prince <dan.prince@rackspace.com>
Group: Applications/Internet
Vendor: Rackspace Email & Apps
License: MIT
URL: http://www.rackspace.com
Source0:	cloud-servers-vpc.tar.gz
BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildArch: noarch
BuildRequires: sed
Requires: monit

%description
Rails application that provides a REST based HTTP interface and web UI to create groups of cloud servers on shared OpenVPN networks.
[GIT_COMMIT_HASH]

%prep
%setup -q -n cloud-servers-vpc

%build

%install
rm -rf %{buildroot}

mkdir -p %{buildroot}/etc/httpd/conf.d/
cp contrib/httpd/cloud_servers_vpc.conf %{buildroot}/etc/httpd/conf.d/

mkdir -p %{buildroot}/etc/monit.d/
cp contrib/monit/cloud_servers_vpc.monit %{buildroot}/etc/monit.d/

mkdir -p %{buildroot}/etc/cron.d/
cp contrib/cron/cloud-servers-vpc %{buildroot}/etc/cron.d/cloud-servers-vpc

mkdir -p %{buildroot}/usr/bin/
cp contrib/bin/* %{buildroot}/usr/bin/

mkdir -p %{buildroot}/opt/cloud-servers-vpc
cp -rp * %{buildroot}/opt/cloud-servers-vpc

mv %{buildroot}/opt/cloud-servers-vpc/contrib/runner_scripts %{buildroot}/opt/cloud-servers-vpc/runner_scripts

# remove a couple directories
rm -rf %{buildroot}/opt/cloud-servers-vpc/contrib/
rm -rf %{buildroot}/opt/cloud-servers-vpc/test/

cd %{buildroot}
find -type f -o -type l | sed "s|^\.||" | sed 's|^|"|' | sed 's|$|"|' > $RPM_BUILD_DIR/cloud-servers-vpc.filelist.%{name}
# mark production.rb as config (noreplace)
sed -e "s|\(.*production.rb.*\)|\%config\(noreplace\) \1|" -i $RPM_BUILD_DIR/cloud-servers-vpc.filelist.%{name}
sed -e "s|\(.*cloud_servers_vpc.conf.*\)|\%config\(noreplace\) \1|" -i $RPM_BUILD_DIR/cloud-servers-vpc.filelist.%{name}
cd -

%pre
getent group cloud_servers_vpc &>/dev/null || groupadd cloud_servers_vpc &>/dev/null
getent passwd cloud_servers_vpc &>/dev/null || \
useradd -r -g cloud_servers_vpc -s /sbin/nologin -c "CloudServersVPC" cloud_servers_vpc &>/dev/null

%post
mkdir -p /opt/cloud-servers-vpc/tmp/pids
mkdir -p /opt/cloud-servers-vpc/log
touch /opt/cloud-servers-vpc/log/production.log
chmod 664 /opt/cloud-servers-vpc/log/production.log
chown -R cloud_servers_vpc /opt/cloud-servers-vpc
chgrp -R cloud_servers_vpc /opt/cloud-servers-vpc
touch /etc/cron.d/

%clean
rm -rf %{buildroot}
rm ../cloud-servers-vpc.filelist.%{name}

%files -f ../cloud-servers-vpc.filelist.%{name}
%defattr(-,root,root,-)
%doc

%changelog
* Tue Sep 21 2010 Dan Prince <dan.prince@rackspace.com> - 1.6.0
- Rename to Cloud Servers VPC.
- Updated to use ruby-cloudservers API.
- Add support for Ubuntu and Fedora.
- Security fix for issue where users could make themselves administrators.
- Add checkbox for is_admin on the edit users page (admin's only).
- Eager load accounts and users on the servers and server_groups pages. This
  improves page load time on the server history page.
- Display the account on the servers page.
- Attempt to ifdown eth0 up to 5 times when initially configuring a client.
- Allow at least 2 minutes to perform the server online check.
- Back to TCP for OpenVPN. Some distros (Ubuntu) seem to get connection errors with UDP.
- Updated to use rackspace/ruby-cloudservers instead of the rackspace-cloud gem.
- Write out the SSH identity file using OpenVPN lib.
* Tue Sep 3 2010 Dan Prince <dan.prince@rackspace.com> - 1.5.1
- Fix an issue where account credentials were being cached in
  the Rackspace::Connection class.
- Fix an issue where cloud servers failed to be deleted due to 
  cloud account initialization.
* Tue Sep 2 2010 Dan Prince <dan.prince@rackspace.com> - 1.5.0
- Add support for multiple user accounts.
- OpenVPN now uses UDP instead of TCP.
- Display the number of servers in each group on the server groups page.
- Capture cloud server HTTP response body errors when they occur.
- Add a random number to the cloud server name on a retry.
- Disable the eth0 interface on OpenVPN clients on reboot.
* Tue Aug 17 2010 Dan Prince <dan.prince@rackspace.com> - 1.4.0
- Updated to require Rails 2.3.8.
- Add API call to rebuild servers.
* Wed Jul 13 2010 Dan Prince <dan.prince@rackspace.com> - 1.3.1
- Keep track of cloud server ID in server_errors table.
- Add cloud-servers-vpc-cleanup-servers script to cleanup/prune servers
  unused servers that can accumulate over time.
- Move to /opt/cloud-servers-vpc.
- Cron job to run cloud-servers-vpc-cleanup every 15 minutes.
* Wed Jun 30 2010 Dan Prince <dan.prince@rackspace.com> - 1.3.0
- Keep track of server history.
- Added server errors table to track individual errors for each retry.
- Select a single job at a time from the DJ queue.
- Added EPEL_BASE_URL setting to allow a custom EPEL base URL to
  be specified.
* Wed Jun 21 2010 Dan Prince <dan.prince@rackspace.com> - 1.2.1
- Retry CS delete commands that fail.
- Use updated_at time when determining the server online timeout.
* Wed Jun 4 2010 Dan Prince <dan.prince@rackspace.com> - 1.2.0
- Add owner name to server groups.
* Wed May 20 2010 Dan Prince <dan.prince@rackspace.com> - 1.1.3
- Set status to failed if it is the 3rd retry. DJ tuning.
* Wed May 17 2010 Dan Prince <dan.prince@rackspace.com> - 1.1.2
- Exit OpenVPN client/server installs if server is already online.
* Wed May 10 2010 Dan Prince <dan.prince@rackspace.com> - 1.1.1
- Fix: Open VPN server now installs on Centos 5.4.
* Wed May 6 2010 Dan Prince <dan.prince@rackspace.com> - 1.1.0
- Server groups now support the ability to set domain name.
* Wed Apr 29 2010 Dan Prince <dan.prince@rackspace.com> - 1.0.1
- Fix issue where an initially failed OpenVPN client might
  cause a retry loop.
* Wed Apr 24 2010 Dan Prince <dan.prince@rackspace.com> - 1.0.0
- Initial 1.0.0 tagged release
* Wed Feb 17 2010 Dan Prince <dan.prince@rackspace.com>
- Initial dev release
