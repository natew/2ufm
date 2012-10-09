class UsersController < ApplicationController
  before_filter :authenticate_user!, :except => [:index, :new, :create, :activate, :live, :tune, :feed]
  before_filter :load_user, :only => [:followers, :following, :feed]

  def show
    @station = Station.find_by_slug(params[:id]) || not_found
    @user = User.find(@station.user_id) || not_found
    @songs = @user.station.songs.playlist_order_broadcasted.page(params[:page]).per(12)
    @artists = @user.station.artists.has_image.order('random() desc').limit(12)
    @primary = @user

    respond_to do |format|
      format.html { render 'show' }
    end
  end

  def feed
    @feed = true

    respond_to do |format|
      format.html { render 'users/show' }
    end
  end

  def tune
    @id = params[:id]
    render layout: false
  end

  def live
    @live = true
    @user = User.find_by_username(params[:id])
    @subscribe_to = "/listens/#{@user.id}"
    listen = @user.listens.last
    song = listen.song
    listen_seconds_ago = Time.now - listen.created_at
    @listen = listen if listen_seconds_ago < song.seconds
  end

  def navbar
    only = { :only => [:id, :user_id, :title, :slug] }
    @online = current_user.stations.user_station.with_user.online.limit(5).to_json(only)
    @offline = current_user.stations.user_station.with_user.not_online.limit(12).to_json(only)
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
    @users = User.all

    respond_to do |format|
      format.html
    end
  end

  def edit
    return if params[:user].nil?

    # Old pass
    old_pass = params[:user][:old_password]
    params[:user].delete :old_password

    current_user.avatar.destroy if params[:avatar]

    if params[:user][:username] != current_user.username and Station.find_by_slug(params[:user][:username])
      flash[:notice] = 'Station name taken'
    else
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
  end

  def new
    if request.xhr?
      unless params[:login].nil?
        if User.count(:conditions => { :login => params[:login] }).zero?
          render :text => 'Username <span>available</span>'
        else
          render :text => 'Username <span>already taken</span>'
        end
      end
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
