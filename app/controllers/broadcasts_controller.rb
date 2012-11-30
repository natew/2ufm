class BroadcastsController < ApplicationController
  before_filter :authenticate_user!, :clear_cache

  def create
    @broadcast = current_user.station.broadcasts.create(song_id: params[:song_id])
    @locals = { :action => 'remove', :id => params[:song_id], :counter => :add }

    respond_to do |format|
      format.js { render :partial => 'broadcast' }
    end
  end

  def destroy
    current_user.station.updated_at = Time.now
    current_user.station.save
    if current_user.station.broadcasts.where(song_id: params[:id]).first.destroy
      @locals = { :action => 'add', :id => params[:id], :counter => :subtract }

      respond_to do |format|
        format.js { render :partial => 'broadcast' }
      end
    else
      head 500
    end
  end

  private

  def clear_cache
    expire_fragment('song_' + (params[:song_id] || params[:id]))
    expire_fragment("user_artists_#{current_user.id}")
    expire_fragment('playlist_new')
  end
end
