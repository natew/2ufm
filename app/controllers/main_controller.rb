class MainController < ApplicationController
  def index
    @popular = Station.popular
    @popular_songs = Song.popular
    @artists = Artist.order('random()').limit(6)

    @stations = {}
    @stations[:featured] = Station.blog_station.order('broadcasts_count desc').limit(4)
    @stations[:trending] = Station.blog_station.order('follows_count desc').limit(4)
    @stations[:artists] = Station.blog_station.order('random() asc').limit(4)
    @stations[:users] = Station.blog_station.order('random()*random()').limit(4)

    if user_signed_in? and !current_user.following_songs.empty?
      @has_songs = true
    end

    @catchphrases = [
      'Take the work out of finding new music',
      'We\'re like your new hipster music friend',
      'The best new music found today',
      'Find awesome new music, before your friends',
      'It\'s too hard to keep up with new music',
      'Want to find new music without the hassle?'
    ]

    if !user_signed_in?
      @new = Station.newest
      @new_songs = Song.newest
    else
      @stations = current_user.stations
    end

    respond_to do |format|
      format.html
    end
  end

  def search
    songs = search_ready(
      :title => 'Songs',
      :items => Song.search_by_name(params[:q]).limit(5) | Song.search_by_artist_name(params[:q]).limit(5),
      :json => { :only => ['full_name', 'slug'], :methods => 'full_name' }
    )

    artists = search_ready(
      :title => 'Artists',
      :items => Artist.search_by_name(params[:q]).limit(5),
      :json => { :only => ['name', 'slug'] }
    )

    stations = search_ready(
      :title => 'Stations',
      :items => Station.search_by_title(params[:q]).limit(5),
      :json => {:only => ['title', 'slug'] }
    )

    render :text => "[#{songs}#{artists}#{stations[0..-2]}]"
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
      puts result
      result[1,result.length-2] + ','
    else
      result = "#{header}{\"name\":\"No Results\",\"selectable\":\"false\"},"
    end
  end
end
