class MainsController < ApplicationController
  def index
    return redirect_to feed_user_path(current_user) if user_signed_in? and request.fullpath.length == 1 and params[:listen].nil?
    @title = 'Discover and share great music'
    @playlist = { station: Station.fake(title: 'Weekly Most Listened'), songs: Song.playlist_popular_week }
    @artists = Station.shelf.artist_station.has_artist_image.has_songs(10).order('random() desc').limit(11)

    respond_to do |format|
      format.html { render 'index' }
      format.page { render_page @playlist }
    end
  end

  def about
    @title = 'About Us'
  end

  def privacy
    @title = 'Privacy Policy'
  end

  def legal
    @title = 'Legal'
  end

  def contact
    @title = 'Contact Us'
  end

  def loading
    render :text => '<div id="loading"><h2>Loading</h2></div>'
  end

  def mac
    send_file File.join(Rails.root,'public','apps','2u.zip')
  end

  def search
    livesearch = params[:q] ? true : false
    @query = params[:q] || params[:get_query].gsub(/\+/, ' ')
    @songs = Song.fuzzy_search_by_name_or_artist_name(@query).matching_id.limit(6)
    @users = User.fuzzy_search_by_full_name_or_station_slug(@query).limit(2)
    @artists = Artist.fuzzy_search_by_name(@query).limit(3)
    @blogs = Blog.fuzzy_search_by_name(@query).limit(2)

    if livesearch
      songs = search_ready(
        title: 'Songs',
        items: @songs,
        json: { only: ['full_name', 'slug'], methods: 'full_name' }
      )

      users = search_ready(
        title: 'Users',
        items: @users,
        json: { only: ['full_name', 'station_slug'] }
      )

      artists = search_ready(
        title: 'Artists',
        items: @artists,
        json: { only: ['name', 'station_slug'] }
      )

      blogs = search_ready(
        title: 'Blogs',
        items: @blogs,
        json: { :only => ['name', 'station_slug'] }
      )

      results = artists + blogs + users + songs
      result = "[#{results[0..-2]}]"

      logger.info result
      render :text => result
    else
      @songs = @songs.with_info_for_playlist_matching_id
      @playlist = { station: Station.fake(title: "Search Results for #{@query}"), songs: @songs }
      @artists = Station.where(artist_id: @artists.map(&:id)) if @artists
      @blogs = Station.where(blog_id: @blogs.map(&:id)) if @blogs
      @users = Station.where(user_id: @users.map(&:id)) if @users

      respond_to do |format|
        format.html { render 'search' }
      end
    end
  end

  private

  # Search formatting
  def search_ready(options)
    header = "{\"name\":\"#{options[:title]}\",\"header\":\"true\"},"

    if options[:items].length > 0
      result = options[:items].to_json(options[:json])
        .gsub(/station_slug\":\"/, 'url":"')
        .gsub(/slug\":\"/, 'url":"songs/')
        .gsub(/full_name|title/,'name')
        .insert(1, header)
      result[1,result.length - 2] + ','
    else
      # result = "#{header}{\"name\":\"No Results\",\"selectable\":\"false\"},"
      result = ""
    end
  end
end
