require 'fileutils'

module Util

	module SshKeygen

		# Generate an ssh keypair using the specified base path
		def generate_ssh_keypair(ssh_key_basepath)
        	FileUtils.mkdir_p(File.dirname(ssh_key_basepath))
			private_key=%{
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA30K1y514BpFsOGrVLVLRcmIM51Z3aHeZ46eGkS3nwz+jD/P7
XRf4lN/8kyRWxyIPw7moh+9T4PPp/vk8aviS+vf8WAjv74jeuJx4cvsW4kTkuv0P
0sILdIRvLbll5Pupf9Xq+K+s6HaLGWRII2S3G1cyZLMWhYZO1dHmt8ugBCyyUuZg
/GwJJMYfB7V118jDVn0NNc9501gAtQ6uv3Xq9uoqgB6r8689pWCffn3Zfb8TOnji
APGKnBHJ0H2TN+L/UVK1C/6G1G+G/fSHp53+HU5VxLoXqpirl25Nmweey3/Awl3u
dijbzmfiLUb9G3s64knpxxeceDt4yUr7y1f7ewIDAQABAoIBAQCTcwiD4I0LsXGK
1SvTkjXX2F/zTUzxhsPw8YxTR8EgV2AHQjjJ4/H9yOyT9VUGkT1eI7jlhi+cixsI
lWzMrTzNWYikT8q/JWMLA/Qc5C3Z5Gw3/rg7loJgQrL2vNJJ59erIQndkpCcuuXl
MDDghzzTZsRWc1y1dN2OI+G/k1EsT2h83DFDFl7vCct5LW9szxYMxRfgQV+eD1x9
Yobno2QuipvnsWyV42DQFiSx+4mo9Ou2L3nPNFYyH9jT8N0lymYsTpbpT1qczYvP
KqDYSUnguBwBLKUxgioY3cuZEJMnzGggstlLauqM77l45ACQn6ly0RTzWSxTSuDG
wkbj3zzZAoGBAPw/PcAzaGosPZvYzn57wjkfs96Y8Nd2DOzzL1GlhAl2cUctAxe1
rcUo9XrGcz4MUBSjt0QzDDn6G9sH4WLnTv125v/Mxnf7FxUZ2iWEYevVLeZq4fsg
F2CChIW+yeJWpJmkxaelruvoXRYDJWNLmc+RelYQ4tCiyIABIhaMO0ONAoGBAOKV
ELe868kA0jd4l5/vVKL5JLlOpGZ0CO5umGqyrMIpNcLPfTD886HhGLIbFFOyUBlJ
XnuDd07CzE5sYVgfLrJpGWBBWkGnd5BOLx6nKgHi88gaayItPHfFnge4fhXVytvO
C0qOhBAiQztazifOHd2YEPzOGCvy1l2ZBTcLRrUnAoGAZOZLJiGqJ6YwsrFj0BZj
F4SF54mX9SfEfde82tTxXvOg1k68CPTkYJREtWrCWFSGh+sA+OfOgTZ5hAC/+Fb8
MskoF7Rqwz2N+yPPLeipXrN0W9HvOQuaLkGnDvTFPqNXzhmp8qiEstrMuWxivThV
e0D/BYRVpg0nVISfhRNs9VUCgYEAnh0RlnYyP4jgKS9w932GnVeoxdtYI9qTJPdu
Sv62SaOCTZiHLzlFNlCi8B6vd5x2Ar9NPHnINuD+uzcsUtcnuf5XY/EW77vSVpQI
k6ZpTPm3zoqI+keA67+ugIrBCbGwJuTIwlVjWPLf4bqDJAnUk377U77p5TlHV/dh
SUEILX8CgYAs4mW7iwprlFMuYlWFwXJYpR2CthR+zCs53Taup6j3GUr45Tu3Y4hQ
rLLD8rqRKVR/T45SVtZpgANrIFlNbSLoqJO4Ulz+tLStol/Mkwbg7yDYmMdNxgqr
3nBZ58pUa4d6LzH0C+1nOMdS9/7i3BxoCNrFLifjehkeedZ9OOV3pg==
-----END RSA PRIVATE KEY-----
}
			public_key="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDfQrXLnXgGkWw4atUtUtFyYgznVndod5njp4aRLefDP6MP8/tdF/iU3/yTJFbHIg/DuaiH71Pg8+n++Txq+JL69/xYCO/viN64nHhy+xbiROS6/Q/Swgt0hG8tuWXk+6l/1er4r6zodosZZEgjZLcbVzJksxaFhk7V0ea3y6AELLJS5mD8bAkkxh8HtXXXyMNWfQ01z3nTWAC1Dq6/der26iqAHqvzrz2lYJ9+fdl9vxM6eOIA8YqcEcnQfZM34v9RUrUL/obUb4b99Iennf4dTlXEuheqmKuXbk2bB57Lf8DCXe52KNvOZ+ItRv0bezriSenHF5x4O3jJSvvLV/t7 dan.prince@dovetail"

			File.open(ssh_key_basepath, 'w') {|f| f.write(private_key) }
			File.open(ssh_key_basepath+".pub", 'w') {|f| f.write(public_key) }
			return true
		end

	end

end
