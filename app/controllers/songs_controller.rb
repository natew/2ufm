class SongsController < ApplicationController
  def index
    @popular = Song.most_favorited(:limit => 25)
    
    respond_to do |format|
      format.html
      format.js { render :layout => false }
    end
  end
  
  def show
    @post = Song.find(params[:id])
  end
end
