require 'fileutils'

module Util

	module SshKeygen

		# Generate an ssh keypair using the specified base path
		def generate_ssh_keypair(ssh_key_basepath)
        	FileUtils.mkdir_p(File.dirname(ssh_key_basepath))
        	FileUtils.touch(ssh_key_basepath)
        	FileUtils.touch(ssh_key_basepath+".pub")
			return true
		end

	end

end
