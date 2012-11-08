class SongsController < ApplicationController
  def go
    song = Song.find(params[:id])
    go_urls = {
      'amazon' => lambda { |song| "http://www.amazon.com/s/ref=nb_ss_dmusic/?tag=bassdo-20&url=search-alias%3Ddigital-music&field-keywords=#{affiliate_searchable(song.artist_name)}%20#{affiliate_searchable(song.name)}" },
      'itunes' => lambda { |song| "http://click.linksynergy.com/fs-bin/stat?id=UAraRlBl3X8&offerid=146261&type=3&subid=0&tmpid=1826&RD_PARM1=http%253A%2F%2Fax.search.itunes.apple.com%2FWebObjects%2FMZSearch.woa%2Fwa%2FadvancedSearch%253FallArtistNames%253D#{URI.encode(affiliate_searchable(song.artist_name))}%2526completeTitle%253D#{URI.encode(affiliate_searchable(song.name))}%2526media%253Dmusic" }
    }
    redirect_to go_urls[params[:to]].call(song)
  end

  def popular
    @title = 'Popular'
    @popular = Station.popular
    @popular_songs = Song.playlist_popular

    respond_to do |format|
      format.html { render 'popular' }
      format.json { render :json => @popular.to_playlist_json }
      format.page { render_page @popular, @popular_songs }
    end
  end

  def trending
    @title = 'Trending'
    @trending = Station.trending
    @trending_songs = Song.playlist_trending

    respond_to do |format|
      format.html { render 'trending' }
      format.json { render :json => @trending.to_playlist_json }
      format.page { render_page @trending, @trending_songs }
    end
  end

  def fresh
    @title = 'Latest'
    @just_in_station = Station.newest
    @just_in_songs = Song.playlist_newest

    respond_to do |format|
      format.html { render 'fresh' }
      format.page { render_page @just_in_station, @just_in_songs }
    end
  end

  def show
    # Song and song playlist
    search_type = (params[:id].is_a?(Numeric) || params[:id].is_numeric?) ? :id : :slug
    @song = Song.where(search_type => params[:id]).first || not_found
    @song_playlist = Song.where(:id => @song.matching_id).playlist_oldest
    @primary = @song

    # Extra info
    @matching_songs = Song.where(matching_id:@song.matching_id).individual.newest
    @blogs = Station.join_songs_on_blog.where(:songs => {:matching_id => @song.matching_id})
    @stats = Broadcast.find_by_sql("SELECT date_part('day', created_at), count(*) from broadcasts where song_id=#{@song.matching_id} group by date_part('day', created_at) order by date_part('day', created_at);").map {|x| [((Time.now.day - x.date_part.to_i).days.ago.to_f*1000).round,x.count.to_i]}

    # Similar songs
    @similar_songs = Song.where('match_name ILIKE (?)', @song.match_name).playlist_trending

    # Blogs songs
    @blog_ids = @blogs.map(&:blog_id)
    @blogs_songs = Song.joins('CROSS JOIN blogs as related_blogs').where('related_blogs.id IN (?)', @blog_ids).playlist_trending

    respond_to do |format|
      format.html { render 'show' }
    end
  end

  def play
    request_time = params[:key].to_i / 1000
    time = Time.now.to_f.to_i
    difference = time - request_time
    # if difference < 5
      # redirect_to Yetting.s3_url + "/song_files/#{params[:id]}_original.mp3"
    # else
      # head 403
    # end

    redirect_to "/attachments/#{Rails.env}/song_compressed_files/#{params[:token]}.mp3"
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