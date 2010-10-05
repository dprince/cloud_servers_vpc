class ServerErrorsController < ApplicationController

  before_filter :authorize

  # GET /server_errors
  # GET /server_errors.json
  # GET /server_errors.xml
  def index

    if request.format == Mime::XML
      limit=params[:limit].nil? ? 1000: params[:limit]
    else
      limit=params[:limit].nil? ? 50 : params[:limit]
    end

    @server_id=params[:server_id]
    if @server_id.blank? then
 
      if not is_admin
        render :text => "Attempt to view unauthorized records. Admin user required.", :status => "401"
        return false
      end

      @server_errors = ServerError.paginate :page => params[:page] || 1, :per_page => limit, :order => "id DESC"

    else

      if not is_admin
        sg=Server.find(@server_id).server_group
        if session[:user_id] and sg and session[:user_id] != sg.user_id
          render :text => "Attempt to view an unauthorized record.", :status => "401"
          return false
        end
      end

      @server_errors = ServerError.paginate :page => params[:page] || 1, :per_page => limit, :conditions => ["server_id = ?", @server_id], :order => "id DESC"

    end

    respond_to do |format|
      #format.html # index.html.erb
      format.json  { render :json => @server_errors }
      format.xml  { render :xml => @server_errors }
    end
  end

end
