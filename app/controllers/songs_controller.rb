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
    @post = Song.find(params[:id])
  end
end
