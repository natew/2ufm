class ArtistsController < ApplicationController
  before_filter :get_artist_info, :except => [:index]

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

  def popular
    @songs = @artist.station.songs.playlist_order_rank(current_user)

    respond_to do |format|
      format.html { render 'show' }
    end
  end

  def remixes
    render_type 'remixes'
  end

  def originals
    render_type 'originals'
  end

  def mashups
    render_type 'mashups'
  end

  def covers
    render_type 'covers'
  end

  def features
    render_type 'featuring'
  end

  def productions
    render_type 'productions'
  end

  private

  def render_type(method)
    @songs = @artist.station.songs.send(method).playlist_order_broadcasted_by_type(current_user)
    @type = method
    @type_updated_at = @songs.first.broadcasted_at

    respond_to do |format|
      format.html { render 'show' }
    end
  end

  def get_artist_info
    @artist = Artist.find_by_slug(params[:id]) || not_found
    @blogs = @artist.stations.blog_station.distinct
    @primary = @artist
  end
end
