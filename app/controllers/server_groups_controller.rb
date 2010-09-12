class ServerGroupsController < ApplicationController

  before_filter :authorize
  before_filter :require_admin_or_self, :only => [:show, :destroy]

  # GET /server_groups
  # GET /server_groups.xml
  def index

	historical_false=0
	# use 'f' on SQLite
	if ServerGroup.connection.adapter_name =~ /SQLite/ then
		historical_false="f"
	end

	if request.format == Mime::XML
	  limit=params[:limit].nil? ? 1000: params[:limit]
	else
	  limit=params[:limit].nil? ? 50 : params[:limit]
	end

	if is_admin then
		@server_groups = ServerGroup.paginate :conditions => ["historical = ?", historical_false], :page => params[:page] || 1, :per_page => limit, :order => "name", :include => [ { :user => [:account] } ]
	else
		@server_groups = ServerGroup.paginate :conditions => ["user_id = ? AND historical = ?", session[:user_id], historical_false], :page => params[:page] || 1, :per_page => limit, :order => "name", :include => [ { :user => [:account] } ]
	end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @server_groups }
    end

  end

  # GET /server_groups/1
  # GET /server_groups/1.xml
  def show
    @server_group = ServerGroup.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @server_group.to_xml(:include => {:servers => {:include => :vpn_network_interfaces}}) }
    end
  end

  # POST /server_groups
  # POST /server_groups.xml
  def create

    respond_to do |format|
			format.html {
    			@server_group = ServerGroup.new(params[:server_group])
    			@server_group.user_id = session[:user_id]
			}
			format.xml {
					#NOTE: investigate why the from_xml fails with:
					# 'Server expected, got Hash'
					# Example: @server_group = @server_group.from_xml(request.raw_post)
					#
					# Below is a work around which manually handles the
					# deserialization from XML
					hash=Hash.from_xml(request.raw_post)

					servers=[]
					ssh_public_keys=[]
					if hash["server_group"]["servers"] then
						hash["server_group"]["servers"].each do |server_hash|
							server = Server.new(server_hash)
							user=User.find(session[:user_id])
							server.account_id = user.account_id
							servers << server
						end
					end

					if hash["server_group"]["ssh_public_keys"] then
						hash["server_group"]["ssh_public_keys"].each do |ssh_key_hash|
							ssh_public_keys << SshPublicKey.new(ssh_key_hash)
						end
					end

					group_hash=hash["server_group"]
					group_hash.delete("servers")
					group_hash.delete("ssh_public_keys")
					group_hash[:user_id] = session[:user_id]
					@server_group = ServerGroup.create(group_hash)
					@server_group.servers << servers
					@server_group.ssh_public_keys << ssh_public_keys
			}
	end

    respond_to do |format|
      if @server_group.save
        flash[:notice] = 'ServerGroup was successfully created.'
        format.html { redirect_to(@server_group) }
        format.xml  { render :xml => @server_group.to_xml(:include => {:servers => {:include => :vpn_network_interfaces}}), :status => :created, :location => @server_group }
      else

		@server_group.errors.each do |error|
			puts error.to_s
		end

        format.html { render :action => "new" }
        format.xml  { render :xml => @server_group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /server_groups/1
  # DELETE /server_groups/1.xml
  def destroy
    @server_group = ServerGroup.find(params[:id])
    xml=@server_group.to_xml
    @server_group.update_attribute('historical', true)
    @server_group.make_historical

    respond_to do |format|
      format.html { redirect_to(server_groups_url) }
      format.xml  { render :xml => xml }
    end

  end

private
	def require_admin_or_self
		return true if is_admin
		server_group = ServerGroup.find(params[:id])
		return true if session[:user_id] and server_group and session[:user_id] == server_group.user_id
		render :text => "Attempt to view an unauthorized record.", :status => "401"
		return false
	end

end
