class SongsController < ApplicationController
  def index
    @station = Station.popular_station.processed.with_posts
    
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
    @station = Station.new_station.processed.with_posts
    
    respond_to do |format|
      format.html
      format.js { render :layout => false }
    end
  end
end