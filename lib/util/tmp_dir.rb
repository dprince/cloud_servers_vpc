require 'tempfile'
require 'fileutils'

module Util

	class TmpDir

		# check out the specified URL into a temp directory
		# returns the path of the temp directory on success
		def self.tmp_dir(prefix="vpc")

			tmp_file=Tempfile.new prefix
			path=tmp_file.path
			tmp_file.close(true)
			FileUtils.mkdir_p path
			return path

		end

	end

end
