require 'fileutils'

module Util

	module SshKeygen

		# Generate an ssh keypair using the specified base path
		def generate_ssh_keypair(ssh_key_basepath)
            FileUtils.mkdir_p(File.dirname(ssh_key_basepath))
        	FileUtils.rm_rf(ssh_key_basepath)
        	FileUtils.rm_rf(ssh_key_basepath+".pub")
        	%x{ssh-keygen -N '' -f #{ssh_key_basepath} -t rsa -q}
		end

	end

end
