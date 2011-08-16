class MainController < ApplicationController
  def index
    @blogs = Blog.limit(10)
    @stations = Station.limit(10)
    @artists = Artist.limit(10)
    
    respond_to do |format|
      format.html
      format.js { render :layout => false }
    end
  end
  
  def search
    render :text => '<li>Result1</li><li>Result2</li>'
  end
end
