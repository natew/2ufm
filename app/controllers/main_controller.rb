class MainController < ApplicationController
  def index
  end
  
  def home
    @popular = Station.find_by_slug('popular-songs')
    @stations = Station.most_favorited(:limit => 6)
    @genres = Genre.all
    
    respond_to do |format|
      format.html
      format.js { render :layout => false }
    end
  end
  
  def search
    render :text => '<li>Result1</li><li>Result2</li>'
  end
  
  def loading
    render :text => '<div id="loading"><h2>Loading</h2></div>'
  end
end
