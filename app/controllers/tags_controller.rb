class TagsController < ApplicationController

  def index
  end

  def show
    @tag = Tag.find_by_slug(params[:id])
    @tag_station = Station.new(title: "#{@tag.name} Station", id: integers_from_string(@tag.name + ' tag-station'))
    @tag_songs = Song.by_tag(@tag).playlist_shuffle
    @playlist = { station: @tag_station, songs: @tag_songs }
    @primary = @tag

    respond_to do |format|
      format.html { render 'show' }
      format.page { render_page @playlist }
    end
  end

end
