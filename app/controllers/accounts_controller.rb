class AccountsController < ApplicationController

  before_filter :authorize
  before_filter :require_admin_or_self, :only => [:update]

  # POST /accounts
  # POST /accounts.xml
  def create
    @account = Account.new(params[:account])

    respond_to do |format|
      if @account.save
        #format.html { redirect_to(@account, :notice => 'Account was successfully created.') }
        format.xml  { render :xml => @account, :status => :created, :location => @account }
      else
        #format.html { render :action => "new" }
        format.xml  { render :xml => @account.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /accounts/1
  # PUT /accounts/1.xml
  def update
    @account = Account.find(params[:id])

    respond_to do |format|
      if @account.update_attributes(params[:account])
        format.html { redirect_to(@account, :notice => 'Account was successfully updated.') }
        #format.xml  { head :ok }
        format.xml  { render :xml => @account }
      else
        #format.html { render :action => "edit" }
        format.xml  { render :xml => @account.errors, :status => :unprocessable_entity }
      end
    end
  end

  private
  def require_admin_or_self
    return true if is_admin
    account = Account.find(params[:id])
    return true if session[:user_id] and account and session[:user_id] == account.user.id
    render :text => "Attempt to view an unauthorized record.", :status => "401"
    return false
  end

end
