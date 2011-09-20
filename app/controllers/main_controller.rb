class MainController < ApplicationController
  def index
  end
  
  def home
    @popular  = Station.popular_station unless user_signed_in?
    @feed     = current_user if user_signed_in?
    @featured = Blog.order('random()').limit(6)
    @genres   = Genre.all
    @artists  = Artist.order('random()').limit(6)
    
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
