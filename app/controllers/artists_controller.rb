class ArtistsController < ApplicationController
  def index
    letter   = params[:letter] || 'a'
    letter   = "0-9" if letter == '0'
    @artists = Artist.where("name ~* '^[#{letter}]'").order('name desc').limit(30)
    
    respond_to do |format|
      format.js { render :layout => false }
      format.html
    end
  end
  
  def show
    @artist  = Artist.find_by_slug(params[:id])
    
    respond_to do |format|
      format.js { render :layout => false }
      format.html
    end
  end
end
