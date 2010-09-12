class UsersController < ApplicationController

  before_filter :require_admin, :only => [:index]
  before_filter :authorize, :except => [:create, :new]
  before_filter :require_admin_or_self, :except => [:create, :new, :index]

  # GET /users
  # GET /users.xml
  def index

    if request.format == Mime::XML
      limit=params[:limit].nil? ? 1000: params[:limit]
    else
      limit=params[:limit].nil? ? 50 : params[:limit]
    end

    @users  = User.paginate :page => params[:page] || 1, :conditions => ["is_active = 1"], :per_page => limit, :order => "username"

    if params[:layout] then
        respond_to do |format|
            format.html # index.html.erb
        end
    else
        respond_to do |format|
          format.html { render :partial => "table" }
          format.xml  { render :xml => @users }
        end
    end

  end

  # GET /users/1
  # GET /users/1.xml
  def show
    @user = User.find(params[:id])
    @account = @user.account

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # GET /users/new
  # GET /users/new.xml
  def new
    @user = User.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # GET /users/1/edit
  def edit
    @user = User.find(params[:id])
  end

  # POST /users
  # POST /users.xml
  def create

    if not is_admin
      if params[:user] and params[:user][:is_admin] == true then
        render :text => "Attempt to view an unauthorized record.", :status => "401"
        return false
      end
    end

    @user = User.new(params[:user])

    respond_to do |format|
      if @user.save
        format.html { redirect_to(@user, :notice => 'User was successfully created.') }
        format.xml  { render :xml => @user, :status => :created, :location => @user }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /users/1
  # PUT /users/1.xml
  def update

    if not is_admin
      if params[:user] and params[:user][:is_admin] == true then
        render :text => "Attempt to view an unauthorized record.", :status => "401"
        return false
      end
    end

    @user = User.find(params[:id])

    respond_to do |format|
      if @user.update_attributes(params[:user])
        format.html { redirect_to(@user, :notice => 'User was successfully updated.') }
        #format.xml  { head :ok }
        format.xml  { render :xml => @user }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.xml
  def destroy
    @user = User.find(params[:id])
    @user.update_attribute("is_active", false)

    respond_to do |format|
      format.html { redirect_to(users_url) }
      format.xml  { render :xml => @user }
    end
  end

  # POST /users/1/password
  def password
    @user = User.find(params[:id])
  end

  private
  def require_admin_or_self
    return true if is_admin
    return true if session[:user_id] and params[:id] and session[:user_id] == params[:id].to_i
    render :text => "Attempt to view an unauthorized record.", :status => "401"
    return false
  end

end
