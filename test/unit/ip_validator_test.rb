require 'test_helper'
require 'util/ip_validator'

class IpValidatorTest < Test::Unit::TestCase

	include Util::IpValidator

	def test_invalid_ip_subnets
		assert !subnets_match?("172.19.0.3","172.19.0.4", "255.255.255.252")
	end


	def test_valid_ip_subnets
		assert subnets_match?("172.19.0.4","172.19.0.5", "255.255.255.252")
		assert subnets_match?("172.19.0.5","172.19.0.6", "255.255.255.252")
	end

end
