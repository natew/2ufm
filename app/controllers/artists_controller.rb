class ArtistsController < ApplicationController
  def index
    @artists = Artist.limit(30)
    
    respond_to do |format|
      format.js { render :layout => false }
    end
  end
  
  def show
    @artist  = Artist.find_by_slug(params[:id])
    @station = @artist.station
    @songs   = @station.songs
    
    respond_to do |format|
      format.js { render :layout => false }
    end
  end
end
