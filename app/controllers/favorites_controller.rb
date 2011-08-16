class FavoritesController < ApplicationController
  before_filter :authenticate_user!, :only => [:add_favorite, :remove_favorite]
  
  def create
    @favorite = Song.find(params[:id]).favorites.build(:user_id => current_user.id)
  
    respond_to do |format|
      if @favorite.save
        format.js { render :partial => 'favorites/remove', :locals => { :id => params[:id] } }
      else
        format.js { render :partial => 'favorites/error' }
      end
    end
  end
  
  def destroy  
    respond_to do |format|
      if Favorite.find_by_favorable_id(params[:id]).destroy
        format.js { render :partial => 'favorites/add', :locals => { :id => params[:id] } }
      else
        format.js { render :partial => 'favorites/error' }
      end
    end
  end
end
