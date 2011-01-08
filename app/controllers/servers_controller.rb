require 'async_exec'

class ServersController < ApplicationController

  before_filter :authorize
  before_filter :require_admin_or_self, :except => [:index, :create]

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
      if not is_admin and session[:user_id] and sg and session[:user_id] != sg.user_id
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
      format.json  { render :json => @server }
      format.xml  { render :xml => @server }
    end
  end

  # POST /servers
  # POST /servers.json
  # POST /servers.xml
  def create

    respond_to do |format|
            format.html {
                server_params=params[:server]
                @server = Server.new(server_params)
            }
            format.xml {
                hash=Hash.from_xml(request.raw_post)
                @server=Server.new(hash["server"])
            }
            format.json {
                hash=JSON.parse(request.raw_post)
                @server=Server.new(hash)
            }
    end

    if not @server.server_group.nil? and session[:user_id] != @server.server_group.user_id and not is_admin then
      render :text => "Attempt to create server in a group you don't own.", :status => "401"
      return false
    end

    user=User.find(session[:user_id])
    @server.account_id = user.account.id

    respond_to do |format|
      if @server.save

        vpn_server=Server.find(:first, :conditions => ["server_group_id = ? AND openvpn_server = ?", @server.server_group_id, true])
        if not vpn_server.nil? and vpn_server.status == "Online" then
          AsyncExec.run_job(CreateCloudServer, @server.id, true)
        else
          AsyncExec.run_job(CreateCloudServer, @server.id)
        end

        flash[:notice] = 'Server was successfully created.'
        format.html  { render :xml => @server.to_xml, :status => :created, :location => @server, :content_type => "application/xml" }
        format.json  { render :json => @server.to_json, :status => :created, :location => @server }
        format.xml  { render :xml => @server.to_xml, :status => :created, :location => @server }
      else

        format.html  { render :xml => @server.errors.to_xml, :status => :unprocessable_entity, :content_type => "application/xml" }
        format.json  { render :json => @server.errors, :status => :unprocessable_entity }
        format.xml  { render :xml => @server.errors, :status => :unprocessable_entity }
      end
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
      AsyncExec.run_job(RebuildServer, @server.id)
      respond_to do |format|
        format.json  { render :xml => @server }
        format.xml  { render :xml => @server }
      end 
    else
      render :text => "Failed to rebuild cloud server.", :status => 500
    end
  end

  # DELETE /servers/1
  # DELETE /servers/1.json
  # DELETE /servers/1.xml
  def destroy
    @server = Server.find(params[:id])
    xml=@server.to_xml
    json=@server.to_json
    @server.update_attribute('historical', true)
    AsyncExec.run_job(MakeServerHistorical, @server.id)

    respond_to do |format|
      format.html { redirect_to(servers_url) }
      format.json  { render :json => json }
      format.xml  { render :xml => xml }
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
