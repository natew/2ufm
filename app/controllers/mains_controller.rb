class MainsController < ApplicationController
  def index
    return redirect_to feed_user_path(current_user) if user_signed_in? and request.fullpath.length == 1 and params[:listen].nil?
    @title = 'Discover and share great music'
    @playlist = { station: Station.fake(title: 'Weekly Most Listened'), songs: Song.playlist_recently_liked }
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
    query = params[:q]

    songs = search_ready(
      title: 'Songs',
      items: Song.fuzzy_search_by_name_or_artist_name(query).matching_id.limit(4),
      json: { only: ['full_name', 'slug'], methods: 'full_name' }
    )

    users = search_ready(
      title: 'Users',
      items: User.fuzzy_search_by_full_name_or_station_slug(query).limit(3),
      json: { only: ['full_name', 'station_slug'] }
    )

    artists = search_ready(
      title: 'Artists',
      items: Artist.fuzzy_search_by_name(query).limit(3),
      json: { only: ['name', 'station_slug'] }
    )

    blogs = search_ready(
      title: 'Blogs',
      items: Blog.fuzzy_search_by_name(query).limit(3),
      json: { :only => ['name', 'station_slug'] }
    )

    result = "[#{artists}#{blogs}#{users}#{songs[0..-2]}]"

    render :text => result
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
