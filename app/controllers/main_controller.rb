class MainController < ApplicationController
  def index
    @feed    = current_user if user_signed_in? and !current_user.songs.empty?
    @popular = Station.popular_station unless @feed
    @artists = Artist.order('random()').limit(6)

    if !user_signed_in?
      @new = Station.new_station(:limit => 12)
      @featured = Blog.order('created_at asc').limit(6)
    else
      @stations = current_user.stations
    end

    respond_to do |format|
      format.html
    end
  end

  def search
    songs   = Song.search_by_name(params[:q]).limit(5) | Song.search_by_artist_name(params[:q]).limit(5)
    artists = Artist.search_by_name(params[:q]).limit(5)
    blogs   = Blog.search_by_name(params[:q]).limit(5)

    render :text => "[#{search_ready('Songs',songs,true)}#{search_ready('Artists',artists)}#{search_ready('Blogs',blogs)[0..-2]}]"
  end

  def loading
    render :text => '<div id="loading"><h2>Loading</h2></div>'
  end

  private

  # Search formatting
  def search_ready(type,records,song=false)
    only   = song ? {only: ['full_name','slug'], methods: 'full_name'} : {only: ['name','slug']}
    header = "{\"name\":\"#{type}\",\"header\":\"true\"},"

    if records.length > 0
      result = records.to_json(only)
        .gsub(/slug\":\"/,"url\":\"#{type.downcase}/")
        .gsub(/full_name/,'name')
        .insert(1, header)
      puts result
      result[1,result.length-2] + ','
    else
      result = "#{header}{\"name\":\"No Results\",\"selectable\":\"false\"},"
    end
  end
end
