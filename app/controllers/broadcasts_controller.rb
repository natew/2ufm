class BroadcastsController < ApplicationController
  before_filter :authenticate_user!

  def create
    @song = Song.find(params[:song_id])
    @broadcast = current_user.station.broadcasts.create(:song_id => @song.id)
    @locals = { :action => 'remove', :id => @broadcast.id, :count => @song.user_broadcasts_count+1 }

    respond_to do |format|
      format.js { render :partial => 'broadcast' }
    end
  end

  def destroy
    @broadcast = Broadcast.where(id: params[:id], station_id: current_user.station.id).first

    if @broadcast
      @song = @broadcast.song
      @broadcast.destroy
      @locals = { :action => 'add', :id => @song.id, :count => @song.user_broadcasts_count }

      respond_to do |format|
        format.js { render :partial => 'broadcast' }
      end
    else
      head 500
    end
  end
end
