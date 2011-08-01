module OpenvpnConfig

require 'util/ssh'

module Bootstrap

	# Cloud servers by default do not have OpenVPN.
	# This function takes care of the installation on various distros.
	def install_openvpn

		epel_base_url_add_command=""
        if not ENV['EPEL_BASE_URL'].nil?
            ENV['EPEL_BASE_URL']
			epel_base_url_add_command="sed -e \"s|#baseurl=EPEL_BASE_URL|baseurl=#{ENV['EPEL_BASE_URL']}|g\" -i /etc/yum.repos.d/epel.repo"
        end

        script=<<-SCRIPT_EOF
		if [ -f /etc/fedora-release ]; then
			yum install -y openvpn ntpdate
		elif [ -f /etc/redhat-release ]; then
			if [ -n "#{ENV['EPEL_BASE_URL']}" ]; then
				cat > /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL <<-"EOF_CAT"
				#{IO.read(File.join(File.dirname(__FILE__), "RPM-GPG-KEY-EPEL"))}
				EOF_CAT
				cat > /etc/yum.repos.d/epel.repo <<-"EOF_CAT"
				#{IO.read(File.join(File.dirname(__FILE__), "epel.repo"))}
				EOF_CAT
				#{epel_base_url_add_command}
			else
				rpm -Uvh http://download.fedora.redhat.com/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm
			fi
			yum install -y openvpn ntp
		elif [ -f /etc/debian_version ]; then
			DEBIAN_FRONTEND=noninteractive apt-get update &> /dev/null || { echo "Failed to update APT repo on $HOSTNAME."; exit 1; }
			DEBIAN_FRONTEND=noninteractive apt-get install -y openvpn ntpdate &> /dev/null || { echo "Failed to install OpenVPN via apt-get on $HOSTNAME."; exit 1; }
			DEBIAN_FRONTEND=noninteractive apt-get install -y chkconfig &> /dev/null || { echo "Failed to install chkconfig via apt-get on $HOSTNAME."; exit 1; }
			sed -e "s|.*HashKnownHosts.*|    HashKnownHosts no|g" -i /etc/ssh/ssh_config
		else
			echo "Unable to install openvpn package."
			exit 1
		fi

		# Run ntpdate to sync server time
		if [ -z "#{ENV['NTP_SERVER']}" ]; then
			ntpdate pool.ntp.org
		else
			ntpdate "#{ENV['NTP_SERVER']}"
		fi

		SCRIPT_EOF
return Util::Ssh.run_cmd(@external_ip_addr, script, @ssh_as_user, @ssh_identity_file, @logger)

	end

end

end
