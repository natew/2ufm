class ArtistsController < ApplicationController
  before_filter :get_artist_info, :except => [:index]

  def index
    letter   = params[:letter] || 'a'
    letter   = "0-9" if letter == '0'
    @artists = Artist.where("name ~* '^[#{letter}]'").order('name desc').limit(30)

    respond_to do |format|
      format.html
    end
  end

  def show
    @songs = @artist.station.songs.playlist_order_broadcasted

    respond_to do |format|
      format.html
    end
  end

  def popular
    @songs = @artist.station.songs.playlist_order_rank

    respond_to do |format|
      format.html { render 'show' }
    end
  end

  def remixes
    render_type @artist.station.songs.remixes
  end

  def originals
    render_type @artist.station.songs.originals
  end

  def mashups
    render_type @artist.station.songs.mashups
  end

  def covers
    render_type @artist.station.songs.covers
  end

  def features
    render_type @artist.station.songs.featuring
  end

  def productions
    render_type @artist.station.songs.productions
  end

  private

  def render_type(songs)
    @songs = songs.playlist_order_broadcasted_by_type

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
