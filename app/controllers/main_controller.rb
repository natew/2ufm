class MainController < ApplicationController
  def index
    @popular = Song.most_favorited(:limit => 12)
    
    respond_to do |format|
      format.html
      format.js { render :layout => false }
    end
  end
  
  def search
    render :text => '<li>Result1</li><li>Result2</li>'
  end
end
