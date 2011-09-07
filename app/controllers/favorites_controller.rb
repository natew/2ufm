class FavoritesController < ApplicationController
  before_filter :authenticate_user!, :only => [:create, :destroy]
  
  def create
    @favorite = Favorite.build_by_type(:type => params[:type], :id => params[:id], :user_id => current_user.id)
  
    respond_to do |format|
      if @favorite.save
        format.js { render :partial => "#{params[:type].pluralize}/favorite_remove", :locals => locals(params[:id]) }
      else
        format.js { render :text => 'error' }
      end
    end
  end
  
  def destroy  
    type = params[:type] || 'Song'
    respond_to do |format|
      if Favorite.find_by_favorable_id(params[:id]).destroy
        format.js { render :partial => "#{params[:type].pluralize}/favorite_add", :locals => locals(params[:id]) }
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
