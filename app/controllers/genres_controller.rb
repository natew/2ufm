class GenresController < ApplicationController
  before_filter :adjust_genres, :find_genre, except: [:index]

  def index
  end

  def shuffle
    find_genre if @genre.nil?
    create_genre_station('shuffle')
    @genre_songs = Song.by_genre(@genre).playlist_shuffle
    render_genre_show
  end

  def trending
    find_genre if @genre.nil?
    create_genre_station('trending')
    @genre_songs = Song.by_genre(@genre).playlist_trending
    render_genre_show
  end

  def show
    find_genre if @genre.nil?
    if @genre.active
      create_genre_station('latest')
      @genre_songs = Song.by_genre(@genre).playlist_newest
      render_genre_show
    else
      self.artists
      render action: 'artists'
    end
  end

  def artists
    @artists = Station.artists_from_genre(@genre.slug, params[:page])
  end

  private

  def create_genre_station(type)
    @genre_station = Station.new(title: "#{@genre.name} #{type.capitalize}", id: integers_from_string(@genre.name + type))
  end

  def find_genre
    @genre = Genre.find_by_slug(params[:id])
    @primary = @genre
  end

  def render_genre_show
    @playlist = { station: @genre_station, songs: @genre_songs }

    respond_to do |format|
      format.html { render 'show' }
      format.page { render_page @playlist }
    end
  end

  def adjust_genres
    params[:id] = 'rap' if params[:id] == 'hip-hop'
  end
end
