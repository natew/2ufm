class UsersController < ApplicationController
  before_filter :authenticate_user!, :except => [:index, :new, :create, :activate, :live, :tune, :feed]
  before_filter :load_user, :only => [:followers, :following]

  def index
    if params[:letter]
      letter = params[:letter]
      letter = "0-9" if letter == '0'
      @users = Station.user_station.where("title ~* '^[#{letter}]'").order('title desc').page(params[:page]).per(Yetting.per)
    else
      @users = Station.has_songs.user_station.order('random() desc').limit(12)
    end

    respond_to do |format|
      format.html
    end
  end

  def show
    @station = Station.find_by_slug(params[:id]) || not_found
    @user = User.find(@station.user_id) || not_found
    @songs = true
    @artists = @user.station.artists.has_image.order('random() desc').limit(12)
    @primary = @user

    respond_to do |format|
      format.html { render 'show' }
      format.page { render_page @station }
    end
  end

  def genres
    added_genres = current_user.set_genres(params[:genres].split(','))
    if added_genres.size > 0
      current_user.update_attributes(first_time:false)
      @artists_stations = Station.where(slug: Artist.joins(:genres).where(genres: { id: added_genres }).map(&:station_slug)).order('stations.songs_count desc').limit(50)
      render partial: 'users/recommended_artists'
    else
      head 500
    end
  end

  def find_friends
    @facebook_friends = current_user.facebook_friends
  end

  def feed
    @user = User.find_by_slug(params[:id]) || current_user
    @primary = @user
    @feed = true

    respond_to do |format|
      format.html do
        @feed_songs = @user.following_songs(params[:p] || 1)
        render 'users/show'
      end
      format.page { render_page @user.feed_station, @user.following_songs(params[:p], true), true }
    end
  end

  def tune
    @id = params[:id]
    render layout: false
  end

  def live
    @live = true
    @user = User.find_by_slug(params[:id])
    if @user
      if @user.privacy.broadcasting
        @subscribe_to = "/listens/#{@user.id}"
        listen = @user.listens.last
        song = listen.song
        listen_seconds_ago = Time.now - listen.created_at
        @listen = listen if listen_seconds_ago < song.seconds
      end
    else
      render status: 404
    end
  end

  def navbar
    only = { :only => [:id, :user_id, :full_name, :title, :slug] }
    max = 20
    online = current_user.stations.select_for_navbar.user_station.with_user.online.limit(max)
    max -= online.length
    @online = online.to_json(only)
    @offline = current_user.stations.select_for_navbar.user_station.with_user.not_online.limit(max).to_json(only) if max > 0
    render :layout => false
  end

  def following
    @following = @user.following

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

  def edit
    return if params[:user].nil?

    # Old pass
    old_pass = params[:user][:old_password]
    params[:user].delete :old_password

    current_user.avatar.destroy if params[:avatar]

    if params[:user][:username] and params[:user][:username] != current_user.username and Station.find_by_slug(params[:user][:username])
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

  def unsubscribe
    @user = User.find_by_confirmation_token(params[:key])

    if @user
      @popular = Station.popular
      @popular_songs = Song.playlist_order_popular
      @user.privacy.unsubscribe(params[:type].pluralize)
      @success = true
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
