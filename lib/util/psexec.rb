module Util

	module Psexec

    PSEXEC_CMD="PsExec.exe"

	def self.run_bat_script(opts)

		raise "Missing script parameter." if not opts[:script]
		raise "Missing password parameter." if not opts[:password]
		raise "Missing ip parameter." if not opts[:ip]
		opts[:flags] = "-c -f -i 0" if not opts[:flags]
		opts[:user] = "Administrator" if not opts[:user]
		logger = opts[:logger]

		tmp_dir=Util::TmpDir.tmp_dir
		bat_script=File.new(File.join(tmp_dir, "exec.bat"), "w")
		old_pwd=Dir.pwd

		begin

			bat_script.write(opts[:script])
			bat_script.flush

			Dir.chdir(tmp_dir)
			output = %x{#{PSEXEC_CMD} #{opts[:flags]} -u #{opts[:user]} -p #{opts[:password]} \\\\#{opts[:ip]} exec.bat}
			retval=$?
			if not logger.nil? then
				if retval
					logger.info(output)
				else
					logger.error(output)
				end
			end
			return retval.success?

		ensure
		Dir.chdir(old_pwd)
			bat_script.close
			File.delete("#{File.join(tmp_dir, 'exec.bat')}")
			Dir.delete(tmp_dir)
		end
	end

	end

end
