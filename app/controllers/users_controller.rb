class UsersController < ApplicationController
  before_filter :authenticate_user!, :except => [:index, :new, :create, :activate, :set_email]
  before_filter :load_user, :only => [:followers, :following]

  def feed
    @user_station = Station.current_user_station
    @user_songs = current_user.following_songs
    @has_songs = true if @user_songs.size > 0
  end

  def navbar
    only = { :only => [:id, :user_id, :title, :slug] }
    @online = current_user.stations.user_station.with_user.online.limit(5).to_json(only)
    @offline = current_user.stations.user_station.with_user.not_online.limit(6).to_json(only)
    @received_songs_notifications = current_user.received_songs_notifications
    render :layout => false
  end

  def following
    @following = @user.stations

    respond_to do |format|
      format.html { render 'users/show' }
    end
  end

  def followers
    @followers = @user.followers

    respond_to do |format|
      format.html { render 'users/show' }
    end
  end

  def index
    @users = User.page(params[:page]).per(25)

    respond_to do |format|
      format.html
    end
  end

  def set_email
    session[:email_address] = params[:email]
    logger.info "set email to " + session[:email_address]
    render :text => ''
  end

  def edit
    return if params[:user].nil?

    # Old pass
    old_pass = params[:user][:old_password]
    params[:user].delete :old_password

    current_user.avatar.destroy if params[:avatar]

    if old_pass.blank?
      current_user.update_without_password(params[:user])
      flash[:notice] = 'Updated profile!'
    elsif current_user.valid_password? old_pass
      current_user.update_with_password(params[:user])
      flash[:notice] = 'Updated password!'
    else
      flash[:notice] = 'Incorrect password.'
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
    @user = User.find_by_slug(params[:id]) || current_user
    @primary = @user
  end
end
