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
      @songs = @user.station.songs.playlist_order_broadcasted(current_user).page(params[:page]).per(12)
      @following = @user.stations
      @followers = @user.followers
      @artists = @user.station.artists.has_image.order('random() desc').limit(12)
      @primary = @user
    when 'blog'
      @blog    = Blog.find(@station.blog_id) || not_found
      @posts   = @blog.posts.order('created_at desc').limit(8)
      @artists = @blog.station.artists.order('random() desc').limit(12)
      @primary = @blog
    when 'artist'
      @artist = Artist.find(@station.artist_id) || not_found
      @blogs = @artist.stations.blog_station.distinct
      @songs = @artist.station.songs.playlist_order_published(current_user)
      @primary = @artist
    end

    respond_to do |format|
      format.html { render @station.type.pluralize + '/show' }
    end
  end
end
