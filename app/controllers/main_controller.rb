class MainController < ApplicationController
  def index
    # Promo
    @promos = Station.blog_station.limit(4)

    # Sidebar Stations
    @blog_stations = Station.blog_station.order('follows_count desc').limit(4)
    @artist_stations = Station.artist_station.order('follows_count desc').limit(8)

    if user_signed_in?
      @user_station = Station.current_user_station
      @user_songs = current_user.following_songs
      @has_songs = true if @user_songs.size
      @user_stations = current_user.stations.order('stations.title asc')
    else
      @new = Station.newest
      @new_songs = Song.playlist_order_published(current_user)
    end

    unless @has_songs
      @popular = Station.popular
      @popular_songs = Song.playlist_order_rank(current_user)
    end

    respond_to do |format|
      format.html
    end
  end

  def search
    query = params[:q]

    songs = search_ready(
      :title => 'Songs',
      :items => Song.fuzzy_search_by_name(query).limit(5) | Song.fuzzy_search_by_artist_name(query).limit(5),
      :json => { :only => ['full_name', 'slug'], :methods => 'full_name' }
    )

    artists = search_ready(
      :title => 'Artists',
      :items => Artist.fuzzy_search_by_name(query).limit(5),
      :json => { :only => ['name', 'url'], :methods => 'url' }
    )

    stations = search_ready(
      :title => 'Stations',
      :items => Station.fuzzy_search_by_title(query).limit(5),
      :json => {:only => ['title', 'slug'] }
    )

    result = "[#{artists}#{stations}#{songs[0..-2]}]"
    logger.info result

    render :text => result
  end

  def loading
    render :text => '<div id="loading"><h2>Loading</h2></div>'
  end

  def mac
    send_file File.join(Rails.root,'public','apps','2u.zip')
  end

  private

  # Search formatting
  def search_ready(options)
    header = "{\"name\":\"#{options[:title]}\",\"header\":\"true\"},"

    if options[:items].length > 0
      result = options[:items].to_json(options[:json])
        .gsub(/slug\":\"/,"url\":\"#{options[:title].downcase}/")
        .gsub(/full_name|title/,'name')
        .insert(1, header)
      result[1,result.length-2] + ','
    else
      result = "#{header}{\"name\":\"No Results\",\"selectable\":\"false\"},"
    end
  end
end
