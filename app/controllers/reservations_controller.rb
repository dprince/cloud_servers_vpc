class ReservationsController < ApplicationController

  before_filter :authorize
  before_filter :require_admin_or_self, :only => [:show, :update, :delete]

  # GET /reservations
  # GET /reservations.json
  # GET /reservations.xml
  def index

    if request.format == Mime::XML
      limit=params[:limit].nil? ? 1000: params[:limit]
    else
      limit=params[:limit].nil? ? 50 : params[:limit]
    end

    @reservations = Reservation.paginate :page => params[:page] || 1, :per_page => limit, :conditions => ["user_id = ? AND historical = ?", session[:user_id], 0], :order => "id"

    respond_to do |format|
      format.xml  { render :xml => @reservations }
      format.any  { render :json => @reservations }
    end
  end

  # GET /reservations/1
  # GET /reservations/1.json
  # GET /reservations/1.xml
  def show
    @reservation = Reservation.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json  { render :json => @reservation, :include => :image }
      format.xml  { render :xml => @reservation, :include => :image }
    end
  end

  # POST /reservations
  # POST /reservations.json
  # POST /reservations.xml
  def create
    @reservation = Reservation.new(params[:reservation])
    @reservation.user_id = session[:user_id]

    respond_to do |format|
      if @reservation.save
        format.xml  { render :xml => @reservation, :status => :created, :location => @reservation, :include => :image }
        format.any  { render :json => @reservation, :status => :created, :location => @reservation, :include => :image }
      else
        format.xml  { render :xml => @reservation.errors, :status => :unprocessable_entity }
        format.any  { render :json => @reservation.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /reservations/1
  # PUT /reservations/1.json
  # PUT /reservations/1.xml
  def update
    @reservation = Reservation.find(params[:id])

    respond_to do |format|
      if @reservation.update_attributes(params[:reservation]) and @reservation.sync
        format.html { redirect_to(@reservation, :notice => 'Reservation was successfully updated.') }
        format.json  { render :json => @reservation, :include => :image }
        format.xml  { render :xml => @reservation, :include => :image }
      else
        format.xml  { render :xml => @reservation.errors, :status => :unprocessable_entity }
        format.any  { render :json => @reservation.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /reservations/1
  # DELETE /reservations/1.json
  # DELETE /reservations/1.xml
  def destroy
    @reservation = Reservation.find(params[:id])
    xml=@reservation.to_xml
    json=@reservation.to_json
    @reservation.make_historical

    respond_to do |format|
      format.html { redirect_to(reservations_url) }
      format.json  { render :json => json}
      format.xml  { render :xml => xml}
    end
  end

  private
  def require_admin_or_self
    return true if is_admin
    reservation = Reservation.find(params[:id])
    return true if session[:user_id] and reservation and reservation.user_id and session[:user_id] == reservation.user_id
    render :text => "Attempt to view an unauthorized record.", :status => "401"
    return false
  end

end
