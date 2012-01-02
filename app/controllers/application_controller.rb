class ApplicationController < ActionController::Base

	helper :all # include all helpers, all the time
	#protect_from_forgery # See ActionController::RequestForgeryProtection for details

	# Scrub sensitive parameters from your log
	# filter_parameter_logging :password

	#before_filter :authorize

	def authorize

		authenticate_with_http_basic do |username, password|

			user = User.authenticate(username, password)
			if user then
				session[:user_id] = user.id
				return true
			end

		end

		if session[:user_id] then
			user=User.find(session[:user_id])
			return true if user.is_active
		end

		redirect_to("/")
		return false

	end

private

	def is_admin
	
		user_id=session[:user_id]
		user=nil
		if user_id
			user=User.find(user_id)
			return true if not user.nil? and user.is_admin
		end
		return false

	end

	def require_admin
	
		if not is_admin
			render :text => "This action requires an Administrator.", :status => "401"
			return false
		end

	end

end
