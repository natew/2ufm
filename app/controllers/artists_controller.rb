class ArtistsController < ApplicationController
  before_filter :get_artist_info, :except => [:index, :show]

  def index
    if params[:genre]
      @artists = Station
                .has_songs
                .joins('inner join artists on artists.id = stations.artist_id')
                .joins('inner join artists_genres on artists_genres.artist_id = artists.id')
                .joins("inner join genres on genres.id = artists_genres.genre_id")
                .where(genres: { slug: params[:genre] })
                .order('random() desc')
                .page(params[:page])
                .per(Yetting.per)
    else
      @artists = Station.artist_station.has_songs.order('random() desc').limit(12)
    end

    @artists_genres = Hash[*
                      Station
                        .where(artist_id: @artists.map(&:artist_id))
                        .select("stations.artist_id as id, string_agg(genres.name, ', ') as artist_genres")
                        .has_songs
                        .joins('inner join artists on artists.id = stations.artist_id')
                        .joins('inner join artists_genres on artists_genres.artist_id = artists.id')
                        .joins("inner join genres on genres.id = artists_genres.genre_id")
                        .group('stations.artist_id')
                        .map{ |s| [s.id, s.artist_genres] }.flatten
                    ]

    @artists.each do |station|
      station.content = @artists_genres[station.artist_id]
    end

    respond_to do |format|
      format.html
    end
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
    @songs = @artist.station.songs.join_author_and_role(@artist.id, 'original').where(original_song: true).playlist_broadcasted
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
    @blogs = @artist.stations.blog_station.distinct
    @artist_has_remixes_of = artist_remixes_of.count > 0
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
