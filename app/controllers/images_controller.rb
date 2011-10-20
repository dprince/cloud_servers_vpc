class ImagesController < ApplicationController

  before_filter :authorize

  # GET /images
  # GET /images.json
  # GET /images.xml
  def index

    if request.format == Mime::XML
      limit=params[:limit].nil? ? 1000: params[:limit]
    else
      limit=params[:limit].nil? ? 50 : params[:limit]
    end

    user=User.find(session[:user_id])
    @images  = Image.paginate :page => params[:page] || 1, :conditions => ["account_id = ?", user.account.id],:per_page => limit, :order => "name"

    if params[:layout] then
        respond_to do |format|
            format.html # index.html.erb
        end
    else
        respond_to do |format|
          format.html { render :partial => "table" }
          format.json  { render :json => @images }
          format.xml  { render :xml => @images }
        end
    end

  end

  # GET /images/1
  # GET /images/1.json
  # GET /images/1.xml
  def show
    @image = Image.find(params[:id])
    if @image.account.user_id != session[:user_id] then
        render :text => "Attempt to view an unauthorized record.", :status => "401"
        return false
    end

    respond_to do |format|
      format.html # show.html.erb
      format.json  { render :json => @image }
      format.xml  { render :xml => @image }
    end
  end

  # GET /images/1/edit
  def edit
    @image = Image.find(params[:id])
    if @image.account.user_id != session[:user_id] then
        render :text => "Attempt to edit an unauthorized record.", :status => "401"
        return false
    end
  end

  # PUT /images/1
  # PUT /images/1.json
  # PUT /images/1.xml
  def update

    @image = Image.find(params[:id])
    if @image.account.user_id != session[:user_id] then
        render :text => "Attempt to update an unauthorized record.", :status => "401"
        return false
    end

    respond_to do |format|
      if @image.update_attributes(params[:image])
        format.html { redirect_to(@image, :notice => 'Image was successfully updated.') }
        format.xml  { render :xml => @image }
        format.json  { render :json => @image }
      else
        format.html { render :action => "edit" }
        format.json  { render :json => @image.errors, :status => :unprocessable_entity }
        format.xml  { render :xml => @image.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /images/1
  # DELETE /images/1.json
  # DELETE /images/1.xml
  def destroy
    @image = Image.find(params[:id])
    if @image.account.user_id != session[:user_id] then
        render :text => "Attempt to delete an unauthorized record.", :status => "401"
        return false
    end
    @image.destroy
    head :ok

  end

  # POST /images/1/sync
  def sync
    user=User.find(session[:user_id])
    AsyncExec.run_job(SyncImages, user.id)
    head :ok
  end

end
