class MainsController < ApplicationController
  def index
    return redirect_to feed_user_path(current_user) if user_signed_in? and request.fullpath.length == 1 and params[:listen].nil?
    @title = 'Discover and share great music'
    @playlist = { station: Station.fake(title: 'Todays Most Listened'), songs: Song.playlist_most_listened(within: 1.day, limit: 15), classname: 'show-count', dont_paginate: true, already_limited: true }
    @artists = Station.shelf.artist_station.has_artist_image.has_songs(10).order('random() desc').limit(11)

    respond_to do |format|
      format.html { render 'index' }
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

  def search
    query = params[:q]

    songs = search_ready(
      title: 'Songs',
      items: Song.fuzzy_search_by_name(query).matching_id.limit(5) | Song.fuzzy_search_by_artist_name(query).matching_id.limit(5),
      json: { only: ['full_name', 'slug'], methods: 'full_name' }
    )

    artists = search_ready(
      title: 'Artists',
      items: Artist.fuzzy_search_by_name(query).limit(4),
      json: { only: ['name', 'station_slug'] }
    )

    blogs = search_ready(
      title: 'Blogs',
      items: Blog.fuzzy_search_by_name(query).limit(3),
      json: { :only => ['name', 'station_slug'] }
    )

    result = "[#{artists}#{blogs}#{songs[0..-2]}]"

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
        .gsub(/station_slug\":\"/, 'url":"')
        .gsub(/slug\":\"/, 'url":"songs/')
        .gsub(/full_name|title/,'name')
        .insert(1, header)
      result[1,result.length-2] + ','
    else
      result = "#{header}{\"name\":\"No Results\",\"selectable\":\"false\"},"
    end
  end
end
