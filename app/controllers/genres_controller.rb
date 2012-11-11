class GenresController < ApplicationController
  def index
    @genres = Genre.ordered
  end

  def show
    params[:id] = 'rap' if params[:id] == 'hip-hop'
    @genre = Genre.find_by_slug(params[:id])
    @genre_station = Station.new(title: @genre.name, id: integers_from_string(@genre.name))
    @primary = @genre

    if true
      @genre_songs = Song.by_genre(@genre).playlist_broadcasted
    else
      @genre_songs = Song.by_genre(@genre).playlist_random
    end

    respond_to do |format|
      format.html { render 'show' }
      format.page { render_page(@genre_station, @genre_songs) }
    end
  end
end
