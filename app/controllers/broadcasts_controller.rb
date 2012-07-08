class BroadcastsController < ApplicationController
  before_filter :authenticate_user!

  def create
    logger.info params
    @broadcast = current_user.station.broadcasts.create(:song_id => params[:song_id])
    @locals = { :action => 'remove', :id => params[:song_id], :counter => :add, :count => 0 }

    respond_to do |format|
      format.js { render :partial => 'broadcast' }
    end
  end

  def destroy
    @broadcast = Broadcast.where(song_id: params[:id], station_id: current_user.station.id).first

    if @broadcast
      @broadcast.destroy
      @locals = { :action => 'add', :id => params[:id], :counter => :subtract, :count => 0 }

      respond_to do |format|
        format.js { render :partial => 'broadcast' }
      end
    else
      head 500
    end
  end
end
