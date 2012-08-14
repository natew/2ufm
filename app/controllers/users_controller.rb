class UsersController < ApplicationController
  before_filter :authenticate_user!, :except => [:index, :new, :create, :activate]
  before_filter :load_user, :except => [:create, :new, :activate, :index, :account, :feed, :stations]

  def feed
    @user_station = Station.current_user_station
    @user_songs = current_user.following_songs
    @has_songs = true if @user_songs.size > 0
  end

  def stations
    @user_stations = current_user.stations.order('stations.title asc')
  end

  def index
    @users = User.page(params[:page]).per(25)

    respond_to do |format|
      format.html
    end
  end

  def edit
    return if params[:user].nil?
    if current_user.update_attributes(params[:user])
      flash[:notice] = 'Updated profile!'
    end
  end

  def new
    if request.xml_http_request?
      unless params[:login].nil?
        if User.count(:conditions => { :login => params[:login] }).zero?
          render :text => 'Username <span>available</span>'
        else
          render :text => 'Username <span>already taken</span>'
        end
      end
    end
  end

  def create
    cookies.delete :auth_token
    @user = User.new(params[:user])
    @user.role = 'user'

    if @user.save
      self.current_user = @user
      UserMailer.welcome_email(@user).deliver
      flash[:notice] = "Welcome!"
      redirect_to @user
    else
      render :action => 'new'
      flash[:notice] = "Error signing up!"
    end
  end

  def activate
    @user = User.find(params[:id].to_i)

    if @user.confirmed?
      @message = 'Account has already been activated!'
    else
      verify = Digest::SHA1.hexdigest(@user.email + '328949126')

      if verify == params[:key]
        if @user.confirm!
          @message = 'Congrats!  Your account has been activated'
        else
          @message = 'Error activating account.  Please contact support.'
        end
      else
        @message = 'Sorry!  Your verification key does not match' + verify
      end
    end
  end

  private

  def load_user
    @user = User.find_by_slug(params[:id])
  end
end
