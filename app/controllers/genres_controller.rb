class GenresController < ApplicationController
  def index
    @genres = Genre.all
  end

  def show
    @genre = Genre.find_by_slug(params[:id])
    @genre_station = Station.new(title:@genre.name, id:'null')
    @genre_songs = Song.by_genre(@genre).playlist_order_broadcasted

    respond_to do |format|
      format.html
    end
  end
end
