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

	def test_range_endpoint
		assert range_endpoint?("172.19.0.3", "/30")
		assert range_endpoint?("172.19.0.4", "/30")
		assert range_endpoint?("172.19.0.7", "/30")
		assert range_endpoint?("172.19.0.8", "/30")
	end

	def test_not_range_endpoint
		assert !range_endpoint?("172.19.0.5", "/30")
		assert !range_endpoint?("172.19.0.6", "/30")
		assert !range_endpoint?("172.19.0.9", "/30")
		assert !range_endpoint?("172.19.0.10", "/30")
	end

end
