class SongsController < ApplicationController
  def index
    @station = Station.popular_station
    
    respond_to do |format|
      format.html
      format.js { render :layout => false }
    end
  end
  
  def show
    @song = Song.find_by_slug(params[:id])
    
    respond_to do |format|
      format.html
      format.js { render :layout => false }
    end
  end
  
  def fresh
    @station = Station.new_station
    
    respond_to do |format|
      format.html
      format.js { render :layout => false }
    end
  end
end