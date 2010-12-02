class ServersController < ApplicationController

  before_filter :authorize
  before_filter :require_admin_or_self, :except => :index

  # GET /servers
  # GET /servers.json
  # GET /servers.xml
  def index

    if request.format == Mime::XML
      limit=params[:limit].nil? ? 1000: params[:limit]
    else
      limit=params[:limit].nil? ? 50 : params[:limit]
    end

	historical=params[:historical]

    if historical.blank? or historical == "false" then
		@historical="0"
	else
		@historical="1"
	end

    @server_group_id=params[:server_group_id]
    if @server_group_id.blank? then
      order="server_group_id, name"
      if @historical == "1"
        order="server_group_id DESC, name"
      end

      conditions=["historical = ?"]
      conditions << @historical

      if not is_admin then
        conditions[0]+=" AND server_group_id IN (SELECT id FROM server_groups WHERE user_id = ?)"
        conditions << session[:user_id]
      end
    
      @servers = Server.paginate :page => params[:page] || 1, :per_page => limit, :conditions => conditions, :order => order, :include => [ :server_group, :account ]

    else

      sg=ServerGroup.find(@server_group_id)
      if session[:user_id] and sg and session[:user_id] != sg.user_id
        render :text => "Attempt to view an unauthorized record.", :status => "401"
        return false
      end

      @servers = Server.paginate :conditions => ["historical = ? and server_group_id = ?", @historical, params[:server_group_id]], :page => params[:page] || 1, :per_page => limit, :order => "name"

    end

    if is_admin
      @server_groups=ServerGroup.find(:all, :conditions => ["historical = 0"], :order => "name")
    else
      @server_groups=ServerGroup.find(:all, :conditions => ["historical = 0 AND user_id = ?", session[:user_id]], :order => "name")
    end

    if params[:layout] then
        respond_to do |format|
          if @historical == "1" then
            format.html { render :action => "index_history" }
          else
            format.html # index.html.erb
          end
        end
    else
      respond_to do |format|
        if @historical == "1" then
          format.html { render :partial => "table_history" }
        else
          format.html { render :partial => "table" }
        end
        format.json  { render :json => @servers }
        format.xml  { render :xml => @servers }
      end
    end

  end

  # GET /servers/1
  # GET /servers/1.json
  # GET /servers/1.xml
  def show
    @server = Server.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json  { render :json => @servers }
      format.xml  { render :xml => @server }
    end
  end

  # POST /servers/1/rebuild
  def rebuild
    @server = Server.find(params[:id])

    if @server.openvpn_server
      render :text => "Rebuilding OpenVPN servers is not supported.", :status => 400
      return
    end

    @server.server_errors.clear
    @server.error_message = ""
    @server.retry_count = 0
    @server.status = "Rebuilding"
    if @server.save then
      Minion.enqueue([ "server.rebuild" ], {"server_id" => @server.id})
      respond_to do |format|
        format.json  { render :xml => @server }
        format.xml  { render :xml => @server }
      end 
    else
      render :text => "Failed to rebuild cloud server.", :status => 500
    end
  end

private
    def require_admin_or_self
        return true if is_admin
        server = Server.find(params[:id])
        return true if session[:user_id] and server and session[:user_id] == server.server_group.user_id
        render :text => "Attempt to view an unauthorized record.", :status => "401"
        return false
    end

end
