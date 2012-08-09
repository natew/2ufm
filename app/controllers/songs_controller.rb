class SongsController < ApplicationController
  def index
    @popular = Station.popular
    @popular_songs = Song.playlist_order_rank(current_user)

    respond_to do |format|
      format.html
      format.json { render :json => @popular.to_playlist_json }
    end
  end

  def show
    # Song and song playlist
    search_type = params[:id].is_numeric? ? :id : :slug
    @song = Song.where(search_type => params[:id]).first || not_found
    @song_playlist = Song.where(:matching_id => @song.matching_id).playlist_order_published(current_user)
    @primary = @song

    # Extra info
    @blogs = Station.join_songs_on_blog.where(:songs => {:matching_id => @song.matching_id})
    @stats = Broadcast.find_by_sql("SELECT date_part('day', created_at), count(*) from broadcasts where song_id=#{@song.matching_id} group by date_part('day', created_at) order by date_part('day', created_at);").map {|x| [((Time.now.day - x.date_part.to_i).days.ago.to_f*1000).round,x.count.to_i]}

    # Similar songs
    #@blog_ids = @blogs.map(&:blog_id)
    #@blogs_songs = Song.joins('CROSS JOIN blogs').where('blogs.id IN (?)', @blog_ids).playlist_order_rank(current_user)
    @artist_ids = Song.find(@song.id).artists.map(&:id)
    @station_ids = Station.where('stations.artist_id IN (?)', @artist_ids)
    @similar_songs = Song.playlist_order_rank(current_user)

    respond_to do |format|
      format.html
    end
  end

  def play
    request_time = params[:key].to_i / 1000
    time = Time.now.to_f.to_i
    difference = time - request_time
    if difference < 2
      redirect_to Yetting.s3_url + "/song_files/#{params[:id]}_original."
    else
      head 403
    end
  end

  def failed
    song = Song.find(params[:id])
    song.report_failure if song
    head 200
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