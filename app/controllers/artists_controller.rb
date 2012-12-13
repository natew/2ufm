class ArtistsController < ApplicationController
  before_filter :get_artist_info, :except => [:index, :show]

  def index
    @random = false
    if params[:genre]
      @artists = Station.artists_from_genre(params[:genre], params[:page])
    else
      @random = true
      @artists = Station.artist_station.has_artist_image.has_songs(3).order('random() desc').limit(17)
    end

    respond_to do |format|
      format.html
    end
  end

  def station
    similar_artists = @artist.similar_artists
  end

  def show
    @station = Station.find_by_slug(params[:id]) || not_found
    @artist = Artist.find(@station.artist_id) || not_found
    get_artist_extra_info
    @songs = @artist.station.songs.playlist_broadcasted
    @primary = @artist
    render_show
  end

  def remixes_of
    @songs = artist_remixes_of.playlist_broadcasted
    @type = 'remixed'
    render_show
  end

  def remixes_by
    render_type 'remixer'
  end

  def originals
    @songs = @artist.station.songs.join_author_and_role(@artist.id, 'original').original.playlist_broadcasted
    @type = 'original'
    render_show
    # render_type 'original'
  end

  def mashups
    render_type 'mashup'
  end

  def covers
    render_type 'cover'
  end

  def features
    render_type 'featured'
  end

  def productions
    render_type 'producer'
  end

  private

  def render_type(type)
    @songs = @artist.station.songs.join_author_and_role(@artist.id, type).playlist_broadcasted
    @type = type
    render_show
  end

  def get_artist_info
    @artist = Artist.find_by_slug(params[:id]) || not_found
    get_artist_extra_info
    @primary = @artist
  end

  def get_artist_extra_info
    @similar_artists = @artist.similar_artists
    @blogs = @artist.stations.blog_station.distinct.limit(8)
    @artist_has_remixes_of = artist_remixes_of.count > 0
  end

  def artist_remixes_of
    @artist.station.songs.joins(:authors).where("authors.role = ? and authors.artist_id != ?", 'remixer', @artist.id)
  end

  def render_show
    @playlist = { station: @artist.station, songs: @songs }
    respond_to do |format|
      format.html { render 'show' }
      format.page { render_page @playlist }
    end
  end
end
