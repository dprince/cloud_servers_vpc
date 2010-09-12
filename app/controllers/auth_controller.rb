class AuthController < ApplicationController

    before_filter :authorize, :only => :logout

    def index
		respond_to do |format|
		  format.html # show.html.erb
		end
    end

    def login
        if request.post?
            user = User.authenticate(params[:username], params[:password])
            if user and user.is_active then
                session[:user_id] = user.id
                flash[:notice] = nil
                redirect_to("/main")
            else
				render :text => "Authentication failed.", :status => 401
            end
        end
    end

    def logout
        session[:user_id] = nil
        head :ok
    end

end
