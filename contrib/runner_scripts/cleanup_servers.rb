require 'timeout'

SERVER_NAME_PREFIX=ENV['SERVER_NAME_PREFIX']
if SERVER_NAME_PREFIX.blank? then
	puts "SERVER_NAME_PREFIX is required in order to use this script."
	exit 1
end
Account.find(:all, :conditions => ["username IS NOT NULL AND username != '' AND api_key IS NOT NULL AND api_key != ''"], :group => "api_key").each do |acct|

	begin
	conn = acct.get_connection
	conn.all_servers do |server|

		exp = Regexp.new("^#{SERVER_NAME_PREFIX}")
		if server[:name] =~ exp then

			server = Server.find(:first, :conditions => ["cloud_server_id_number = ? AND historical = 0", server[:id]])

			if server.nil? then

				begin
					puts "Account: #{acct.cloud_servers_username}, Deleting cloud server ID: #{server[:id]} #{server[:name]}"
					Timeout::timeout(30) do
						conn.update_server(server[:id], {:name => "deleted_#{server[:id]}"})
						conn.delete_server(server[:id])
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
