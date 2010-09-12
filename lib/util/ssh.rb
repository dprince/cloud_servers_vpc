module Util

	module Ssh

		def self.run_cmd(server_name_ip, cmd, user="root", identity_file="#{ENV['HOME']}/.ssh/id_rsa", logger=nil)
				output = ""
				IO.popen("ssh -T -i \"#{identity_file}\" #{user}@#{server_name_ip}", "r+") do |io|
				io.puts(cmd)
				io.close_write
				output = io.readlines
				end
				retval=$?
				if not logger.nil? then
					if retval
						logger.info(output)
					else
						logger.error(output)
					end
				end
				# returns the exit status of the last child
				return retval.success?
		end

	end

end
