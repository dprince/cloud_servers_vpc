class SshPublicKeysController < ApplicationController

  before_filter :authorize
  before_filter :require_admin_or_self, :only => [:update]

  # POST /ssh_public_keys
  # POST /ssh_public_keys.xml
  def create
    @ssh_public_key = SshPublicKey.new(params[:ssh_public_key])

    respond_to do |format|
      if @ssh_public_key.save
        format.xml  { render :xml => @ssh_public_key, :status => :created, :location => @ssh_public_key }
      else
        format.xml  { render :xml => @ssh_public_key.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /ssh_public_keys/1
  # PUT /ssh_public_keys/1.xml
  def update
    @ssh_public_key = SshPublicKey.find(params[:id])

    respond_to do |format|
      if @ssh_public_key.update_attributes(params[:ssh_public_key])
        format.html { redirect_to(@ssh_public_key, :notice => 'SshPublicKey was successfully updated.') }
        format.xml  { render :xml => @ssh_public_key }
      else
        format.xml  { render :xml => @ssh_public_key.errors, :status => :unprocessable_entity }
      end
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
