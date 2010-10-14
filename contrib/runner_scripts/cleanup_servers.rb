require 'timeout'

CS_NAME_PREFIX=ENV['RACKSPACE_CLOUD_SERVER_NAME_PREFIX']
if CS_NAME_PREFIX.blank? then
	puts "RACKSPACE_CLOUD_SERVER_NAME_PREFIX is required in order to use this script."
	exit 1
end
Account.find(:all, :conditions => ["cloud_servers_username IS NOT NULL AND cloud_servers_username != '' and cloud_servers_api_key IS NOT NULL and cloud_servers_api_key != ''"], :group => "cloud_servers_api_key").each do |acct|

	begin
	cs_conn=CloudServersUtil.new(acct.cloud_servers_username, acct.cloud_servers_api_key)
	cs_conn.all_servers do |cs|

		exp=Regexp.new("^#{CS_NAME_PREFIX}")
		if cs[:name] =~ exp then

			server=Server.find(:first, :conditions => ["cloud_server_id_number = ? AND historical = 0", cs[:id]])

			if server.nil? then

				begin
					puts "Account: #{acct.cloud_servers_username}, Deleting cloud server ID: #{cs[:id]} #{cs[:name]}"
					Timeout::timeout(30) do
						cs_server=cs_conn.find_server(cs[:id])
						cs_server.update(:name => "deleted_#{cs[:id]}")
						cs_server.delete!
					end
				rescue
				end

			end

		end

	end

	rescue Exception => e
		puts "Failed to cleanup servers for account: #{acct.id}, #{acct.cloud_servers_username}. #{e.message}"
	end

end
