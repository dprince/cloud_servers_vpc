module Util

    module CertUtil

        def tail_cert(raw_cert)
            new_cert=""
            begin_cert=false
            raw_cert.each_line do |line|
                begin_cert = true if line =~ /-----BEGIN CERTIFICATE-----/
                new_cert += "#{line}" if begin_cert
            end
			new_cert
        end

    end

end
