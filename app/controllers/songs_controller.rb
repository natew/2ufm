class SongsController < ApplicationController
  def index
    @new = Station.new_station
    @popular = Station.popular_station
    
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
end
