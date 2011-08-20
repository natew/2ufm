class FavoritesController < ApplicationController
  before_filter :authenticate_user!, :only => [:create, :destroy]
  
  def create
    type = params[:type] || 'Song'
    object = type.classify.constantize
    @favorite = object.find(params[:id]).favorites.build(:user_id => current_user.id)
  
    respond_to do |format|
      if @favorite.save
        format.js { render :partial => "#{type.pluralize}/favorite_remove", :locals => locals(params[:id]) }
      else
        format.js { render :text => 'error' }
      end
    end
  end
  
  def destroy  
    type = params[:type] || 'Song'
    respond_to do |format|
      if Favorite.find_by_favorable_id(params[:id]).destroy
        format.js { render :partial => "#{type.pluralize}/favorite_add", :locals => locals(params[:id]) }
      else
        format.js { render :text => 'error' }
      end
    end
  end
  
  protected
  
  def locals(id)
    { :id => params[:id], :count => Song.find(id).favorites.count }
  end
end
