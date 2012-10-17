class ArtistsController < ApplicationController
  before_filter :get_artist_info, :except => [:index, :show]

  def index
    if params[:letter]
      letter = params[:letter]
      letter = "0-9" if letter == '0'
      @artists = Artist.where("name ~* '^[#{letter}]'").order('name desc')
    else
      @artists = Artist.order('random() desc').limit(12)
    end

    respond_to do |format|
      format.html
    end
  end

  def show
    @station = Station.find_by_slug(params[:id]) || not_found
    @artist = Artist.find(@station.artist_id) || not_found
    get_artist_extra_info
    @songs = @artist.station.songs.playlist_order_broadcasted
    @primary = @artist
    render_show
  end

  def remixes_of
    @songs = artist_remixes_of.playlist_order_broadcasted
    @type = 'remixed'
    render_show
  end

  def remixes_by
    render_type 'remixer'
  end

  def originals
    @songs = @artist.station.songs.join_author_and_role(@artist.id, 'original').where(original_song: true).playlist_order_broadcasted
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
    @songs = @artist.station.songs.join_author_and_role(@artist.id, type).playlist_order_broadcasted
    @type = type
    render_show
  end

  def get_artist_info
    @artist = Artist.find_by_slug(params[:id]) || not_found
    get_artist_extra_info
    @primary = @artist
  end

  def get_artist_extra_info
    @blogs = @artist.stations.blog_station.distinct
    @artist_has_remixes_of = artist_remixes_of.count
  end

  def artist_remixes_of
    @artist.station.songs.joins(:authors).where("authors.role = ? and authors.artist_id != ?", 'remixer', @artist.id)
  end

  def render_show
    respond_to do |format|
      format.html { render 'show' }
      format.page { render_page @artist.station, @songs }
    end
  end
end
