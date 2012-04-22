class FollowsController < ApplicationController
  before_filter :authenticate_user!

  def create
    @station = Station.find(params[:station_id])
    @follow  = current_user.follows.create(:station_id => @station.id)
    @locals  = { :action => 'remove', :id => @follow.id, :count => @station.follows.count, :changed => true }

    respond_to do |format|
      format.js { render :partial => 'follow' }
    end
  end

  def destroy
    @follow  = Follow.find(params[:id])
    @station = @follow.station
    @follow.destroy
    @locals  = { :action => 'add', :id => @station.id, :count => @station.follows.count, :changed => true }

    respond_to do |format|
      format.js { render :partial => 'follow' }
    end
  end
end
