class SshPublicKeysController < ApplicationController

  before_filter :authorize
  before_filter :require_admin_or_self, :only => [:show, :update, :delete]

  # GET /ssh_public_keys
  # GET /ssh_public_keys.json
  # GET /ssh_public_keys.xml
  def index

    if request.format == Mime::XML
      limit=params[:limit].nil? ? 1000: params[:limit]
    else
      limit=params[:limit].nil? ? 50 : params[:limit]
    end

    @ssh_public_keys = SshPublicKey.paginate :page => params[:page] || 1, :per_page => limit, :conditions => ["user_id = ?", session[:user_id]], :order => "description DESC"

    respond_to do |format|
      format.xml  { render :xml => @ssh_public_keys }
      format.any  { render :json => @ssh_public_keys }
    end
  end

  # GET /ssh_public_keys/1
  # GET /ssh_public_keys/1.json
  # GET /ssh_public_keys/1.xml
  def show
    @ssh_public_key = SshPublicKey.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json  { render :json => @ssh_public_key }
      format.xml  { render :xml => @ssh_public_key }
    end
  end

  # POST /ssh_public_keys
  # POST /ssh_public_keys.json
  # POST /ssh_public_keys.xml
  def create
    @ssh_public_key = SshPublicKey.new(params[:ssh_public_key])
    @ssh_public_key.user_id = session[:user_id]

    respond_to do |format|
      if @ssh_public_key.save
        format.xml  { render :xml => @ssh_public_key, :status => :created, :location => @ssh_public_key }
        format.any  { render :json => @ssh_public_key, :status => :created, :location => @ssh_public_key }
      else
        format.xml  { render :xml => @ssh_public_key.errors, :status => :unprocessable_entity }
        format.any  { render :json => @ssh_public_key.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /ssh_public_keys/1
  # PUT /ssh_public_keys/1.json
  # PUT /ssh_public_keys/1.xml
  def update
    @ssh_public_key = SshPublicKey.find(params[:id])

    respond_to do |format|
      if @ssh_public_key.update_attributes(params[:ssh_public_key])
        format.html { redirect_to(@ssh_public_key, :notice => 'SshPublicKey was successfully updated.') }
        format.json  { render :json => @ssh_public_key }
        format.xml  { render :xml => @ssh_public_key }
      else
        format.xml  { render :xml => @ssh_public_key.errors, :status => :unprocessable_entity }
        format.any  { render :json => @ssh_public_key.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /ssh_public_keys/1
  # DELETE /ssh_public_keys/1.json
  # DELETE /ssh_public_keys/1.xml
  def destroy
    @ssh_public_key = SshPublicKey.destroy(params[:id])
    xml=@ssh_public_key.to_xml
    json=@ssh_public_key.to_json
    @ssh_public_key.destroy

    respond_to do |format|
      format.html { redirect_to(ssh_public_keys_url) }
      format.json  { render :json => json}
      format.xml  { render :xml => xml}
    end
  end

  private
  def require_admin_or_self
    return true if is_admin
    ssh_public_key = SshPublicKey.find(params[:id])
    return true if session[:user_id] and ssh_public_key and ssh_public_key.user_id and session[:user_id] == ssh_public_key.user_id
    render :text => "Attempt to view an unauthorized record.", :status => "401"
    return false
  end

end
