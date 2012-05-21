class SongsController < ApplicationController
  def index
    @popular = Station.popular
    @popular_songs = Song.popular

    respond_to do |format|
      format.html
      format.json { render :json => @popular.to_playlist_json }
    end
  end

  def show
    @song_playlist = Song.where(:slug => params[:id]).playlist_order_published || not_found
    @song = @song_playlist.first
    @primary = @song
    @related_songs = Song.where(:shared_id => @song.shared_id).individual
    @blogs = Station.blog_station.joins(:songs).where('songs.shared_id = ?', @song.shared_id)
    @stats = Broadcast.find_by_sql("SELECT date_part('day', created_at), count(*) from broadcasts where song_id=#{@song.shared_id} group by date_part('day', created_at) order by date_part('day', created_at);").map {|x| [((Time.now.day - x.date_part.to_i).days.ago.to_f*1000).round,x.count.to_i]}

    respond_to do |format|
      format.html
    end
  end

  def fresh
    @station = Station.newest
    @songs = Song.newest

    respond_to do |format|
      format.html
    end
  end

  def failed
    @song = Song.find(params[:id])

    if @song
      @song.failures += 1
      @song.working = false if @song.failures > 10
      @song.save
    end

    respond_to do |format|
      format.html
    end
  end

  def create
    params[:song][:file] = UrlTempfile.new(params[:url])
    @song = Song.new(params[:song])

    respond_to do |format|
      if @song.save!
        format.html { render 'index', notice: 'Posted song!' }
      else
        format.html { render 'index', notice: 'Could not post song!' }
      end
    end
  end
end