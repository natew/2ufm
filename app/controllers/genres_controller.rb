class GenresController < ApplicationController
  def index
    @genres = Genre.all
  end

  def show
    @genre = Genre.find_by_slug(params[:id])
    @genre_station = Station.new(title:@genre.name, id:'null')

    if true
      @genre_songs = Song.by_genre(@genre).playlist_order_broadcasted
    else
      @genre_songs = Song.by_genre(@genre).playlist_order_random
    end

    respond_to do |format|
      format.html { render 'show' }
      format.page { render_page(@genre_station, @genre_songs) }
    end
  end
end
