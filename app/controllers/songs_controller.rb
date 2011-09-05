class SongsController < ApplicationController
  def index
    @new = Station.find_by_slug('new-songs')
    @popular = Station.find_by_slug('popular-songs')
    
    respond_to do |format|
      format.html
      format.js { render :layout => false }
    end
  end
  
  def show
    @post = Song.find(params[:id])
  end
end
