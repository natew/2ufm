class StationsController < ApplicationController

  def index
    @featured_stations = Station.has_parent.order('created_at desc').limit(8)
    @other_stations = Station.has_parent.order('random() desc').limit(8)
    @top_stations = Station.has_parent.order('random()').limit(8)

    respond_to do |format|
      format.html
    end
  end

  def show
    @station = Station.find_by_slug(params[:id]) || not_found

    case @station.type
    when 'user'
      @user = User.find(@station.user_id) || not_found
      @plays = Listen.select('listens.created_at, listens.url, songs.name, songs.slug, users.username, users.station_slug').joins(:song, :user).where(:user_id => @user.id).limit(10)
      @songs = @user.station.songs.playlist_order_broadcasted(current_user).page(params[:page]).per(12)
      @following = @user.stations
      @followers = @user.station.followers
      @artists = @user.station.artists.order('random() desc').limit(16)
      @primary = @user
    when 'blog'
      @blog    = Blog.find(@station.blog_id) || not_found
      @posts   = @blog.posts.order('created_at desc').limit(8)
      @artists = @blog.station.artists.order('random() desc').limit(12)
      @primary = @blog
    when 'artist'
      @artist = Artist.find(@station.artist_id) || not_found
      @blogs = @artist.stations.blog_station.distinct
      @songs = @artist.station.songs.playlist_order_broadcasted(current_user)
      @primary = @artist
    end

    respond_to do |format|
      format.html { render @station.type.pluralize + '/show' }
    end
  end
end
