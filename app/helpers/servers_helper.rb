module ServersHelper

	def image_name(id)

		return case id
		when 51
			"CentOS 5.5"
		when 187811
			"CentOS 5.4"
		when 78
			"Fedora 15 (Lovelock)"
		when 71
			"Fedora 14 (Laughlin)"
		when 53
			"Fedora 13 (Goddard)"
		when 17
			"Fedora 12 (Constantine)"
		when 12
			"Red Hat EL 5.3"
		when 14
			"Red Hat EL 5.4"
		when 62 
			"Red Hat EL 5.5"
		when 76
			"Ubuntu 11.04 (natty)"
		when 69
			"Ubuntu 10.10 (maverick)"
		when 49
			"Ubuntu 10.04 LTS (lucid)"
		when 14362
			"Ubuntu 9.10 (karmic)"
		when 8
			"Ubuntu 9.04 (jaunty)"
		when 10
			"Ubuntu 8.04.2 LTS (hardy)"
		when 4
			"Debian 5.0 (lenny)"
		when 75
			"Debian 6.0 (squeeze)"
		when 23
			"Windows Server 2003 R2 SP2 x64"
		when 24
			"Windows Server 2008 SP2 x64"
		when 40
			"Oracle EL Server Release 5 Update 4"
		when 31
			"Windows Server 2008 SP2 x86"
		when 19
			"Gentoo 10.1"
		when 28
			"Windows Server 2008 R2 x64"
		when 58
			"Windows Server 2008 R2 x64 SQL Server"
		when 55
			"Arch 2010.05"
		when 41
			"Oracle EL JeOS Release 5 Update 3"
		when 29
			"Windows Server 2003 R2 SP2 x86"
		else
			"Unknown"
		end

	end

	def flavor_name(id)
		return case id
		when 1
			"256MB"
		when 2
			"512MB"
		when 3
			"1GB"
		when 4
			"2GB"
		when 5
			"4GB"
		when 6
			"8GB"
		when 7
			"15.5GB"
		else
			"Unknown"
		end
	end

end
