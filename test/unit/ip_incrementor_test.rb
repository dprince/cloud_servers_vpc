require 'test_helper'
require 'util/ip_incrementer'

class IpIncrementerTest < Test::Unit::TestCase

	include Util::IpIncrementer

	def test_init_ip
		init_ip
	end

	def test_init_ip_192
		init_ip("192.168.0.0")
	end

	def test_next_ip
		init_ip("172.19.0.0")
		assert_equal "172.19.0.1", next_ip
	end

end
