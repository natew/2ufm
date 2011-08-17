class FavoritesController < ApplicationController
  before_filter :authenticate_user!, :only => [:create, :destroy]
  
  def create
    @favorite = Song.find(params[:id]).favorites.build(:user_id => current_user.id)
  
    respond_to do |format|
      if @favorite.save
        format.js { render :partial => 'favorites/remove', :locals => favorite_locals(params[:id]) }
      else
        format.js { render :partial => 'favorites/error' }
      end
    end
  end
  
  def destroy  
    respond_to do |format|
      if Favorite.find_by_favorable_id(params[:id]).destroy
        format.js { render :partial => 'favorites/add', :locals => favorite_locals(params[:id]) }
      else
        format.js { render :partial => 'favorites/error' }
      end
    end
  end
  
  protected
  
  def favorite_locals(id)
    { :id => params[:id], :count => Song.find(id).favorites.count }
  end
end
