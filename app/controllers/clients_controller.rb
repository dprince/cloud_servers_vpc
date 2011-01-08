require 'async_exec'

class ClientsController < ApplicationController

  before_filter :authorize
  before_filter :require_admin_or_self, :except => [:index, :create]

  # GET /clients
  # GET /clients.json
  # GET /clients.xml
  def index

    if request.format == Mime::XML
      limit=params[:limit].nil? ? 1000: params[:limit]
    else
      limit=params[:limit].nil? ? 50 : params[:limit]
    end

    @server_group_id=params[:server_group_id]
    if @server_group_id.blank? then

      conditions=[]
      if not is_admin then
        conditions << "server_group_id IN (SELECT id FROM server_groups WHERE user_id = ?)"
        conditions << session[:user_id]
      end
    
      @clients = Client.paginate :page => params[:page] || 1, :per_page => limit, :conditions => conditions, :order => "server_group_id, name", :include => [ :server_group, :vpn_network_interfaces ]

    else

      sg=ServerGroup.find(@server_group_id)
      if not is_admin and session[:user_id] and sg and session[:user_id] != sg.user_id
        render :text => "Attempt to view an unauthorized record.", :status => "401"
        return false
      end

      @clients = Client.paginate :conditions => ["server_group_id = ?", params[:server_group_id]], :page => params[:page] || 1, :per_page => limit, :order => "name"

    end

    if is_admin
      @server_groups=ServerGroup.find(:all, :conditions => ["historical = 0"], :order => "name")
    else
      @server_groups=ServerGroup.find(:all, :conditions => ["historical = 0 AND user_id = ?", session[:user_id]], :order => "name")
    end

    respond_to do |format|
      format.json  { render :json => @clients }
      format.xml  { render :xml => @clients }
    end

  end

  # GET /clients/1
  # GET /clients/1.json
  # GET /clients/1.xml
  def show
    @client = Client.find(:first, :conditions => ["id = ?", params[:id]], :include => :vpn_network_interfaces )
    respond_to do |format|
      format.json  { render :json => @client.to_json(:include => :vpn_network_interfaces) }
      format.xml  { render :xml => @client.to_xml(:include => :vpn_network_interfaces) }
    end
  end

  # POST /clients
  # POST /clients.json
  # POST /clients.xml
  def create

    respond_to do |format|
            format.html {
                client_params=params[:client]
                @client = Client.new(client_params)
            }
            format.xml {
                hash=Hash.from_xml(request.raw_post)
                @client=Client.new(hash["client"])
            }
            format.json {
                hash=JSON.parse(request.raw_post)
                @client=Client.new(hash)
            }
    end

    if not @client.server_group.nil? and session[:user_id] != @client.server_group.user_id and not is_admin then
      render :text => "Attempt to create client in a group you don't own.", :status => "401"
      return false
    end

    respond_to do |format|
      if @client.save

        vpn_server=Server.find(:first, :conditions => ["server_group_id = ? AND openvpn_server = ?", @client.server_group_id, true])
        if not vpn_server.nil? and vpn_server.status == "Online" then
          AsyncExec.run_job(CreateClientVPNCredentials, @client.id)
        end

        flash[:notice] = 'Client was successfully created.'
        format.json  { render :json => @client.to_json, :status => :created, :location => @client }
        format.xml  { render :xml => @client.to_xml, :status => :created, :location => @client }
      else

        format.json  { render :json => @client.errors, :status => :unprocessable_entity }
        format.xml  { render :xml => @client.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /clients/1
  # DELETE /clients/1.json
  # DELETE /clients/1.xml
  def destroy
    @client = Client.find(params[:id])
    xml=@client.to_xml
    json=@client.to_json
    @client.destroy

    respond_to do |format|
      format.json  { render :json => json }
      format.xml  { render :xml => xml }
    end

  end

private
    def require_admin_or_self
        return true if is_admin
        client = Client.find(params[:id])
        return true if session[:user_id] and client and session[:user_id] == client.server_group.user_id
        render :text => "Attempt to view an unauthorized record.", :status => "401"
        return false
    end

end
