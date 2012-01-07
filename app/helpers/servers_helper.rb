module ServersHelper

	def image_name(id)

		image = Image.find(:first, :conditions => ["image_ref = ?", id])
		if image then
            image.name
		else
			"Unknown"
		end

	end

	def flavor_name(id)
		return case id
		when "1"
			"256MB"
		when "2"
			"512MB"
		when "3"
			"1GB"
		when "4"
			"2GB"
		when "5"
			"4GB"
		when "6"
			"8GB"
		when "7"
			"15.5GB"
		else
			"Unknown"
		end
	end

end
