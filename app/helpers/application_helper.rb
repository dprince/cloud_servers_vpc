# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

	def yes_no(val)
		val ? "Yes" : "No"
	end

	def check_or_blank(val)
		val ? "<img class=\"check_image\" src=\"images/check.png\" />" : "&nbsp;"
	end

	def status_image(status, show_image=true)

		image_name = case status
			when "Failed" then "failed"
			when "Online" then "success"
			else "pending"
		end

		if show_image then
			return "<img class=\"status_image\" src=\"/images/#{image_name}.png\"/>&nbsp;#{status}"
		else
			return status
		end

	end

    def status_image_for_group(server_group)

		has_failure=false
		all_success=true
		server_group.servers.each do |server|
			if server.status == "Failed" then
				has_failure=true
				all_success=false
			elsif server.status == "Pending" then
				all_success=false
			end
		end

		image_name="pending"
		status="Pending"
		if has_failure then
			image_name="failed"
			status="Failure"
		elsif all_success then
			image_name="success"
			status="Online"
		end

		return "<img class=\"status_image\" src=\"/images/#{image_name}.png\"/>&nbsp;#{status}"

    end

	def timestamp(dts)
		return dts.strftime('%Y-%m-%d %I:%M%p')
	end

	def is_admin
	
		user_id=session[:user_id]

		if user_id
			user=User.find(user_id)
			return user.is_admin
		end

	end

	def chop_for_html(string, max_length=24)
		if not string.nil? then
			if string.length <= max_length
				h(string)
			else
				"<font title=\"#{h(string)}\">#{h(string[0,max_length])}...</font>"
			end
		else
			string
		end
	end

	def select_for_images(name)

		image_arr=[
			[51, "CentOS 5.5"],
			[187811, "Centos 5.4"],
			[71, "Fedora 14 (Laughlin)"],
			[53, "Fedora 13 (Goddard)"],
			[17, "Fedora 12 (Constantine)"],
			[14, "Red Hat EL 5.4"],
			[62, "Red Hat EL 5.5"],
			[69, "Ubuntu 10.10 (maverick)"],
			[49, "Ubuntu 10.04 LTS (lucid)"],
			[14362, "Ubuntu 9.10 (karmic)"]
		]

		select_str="<select name=\"#{name}\">"

		image_arr.each do |image|
			select_str+="<option value=\"#{image[0]}\">#{image[1]}</option>"
		end

		select_str+="</select>"
		return select_str

	end

	def select_for_flavors(name)

		flavor_arr=[
			[1, "256"],
			[2, "512"],
			[3, "1GB"],
			[4, "2GB"],
			[5, "4GB"],
			[6, "8GB"],
			[7, "15.5GB"]
		]

		select_str="<select name=\"#{name}\">"

		flavor_arr.each do |image|
			select_str+="<option value=\"#{image[0]}\">#{image[1]}</option>"
		end

		select_str+="</select>"
		return select_str

	end

end
