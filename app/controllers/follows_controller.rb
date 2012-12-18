class FollowsController < ApplicationController
  before_filter :authenticate_user!

  def create
    @station = Station.find(params[:station_id])
    @follow  = current_user.follows.create(:station_id => @station.id) rescue ActiveRecord::RecordNotUnique
    @locals  = { :action => 'remove', :id => @station.id, :count => @station.follows_count+1, :changed => true }

    if @station.user and @station.user.mail_follows
      UserMailer.delay.follow(current_user, @station.user)
    end

    respond_to do |format|
      format.js { render :partial => 'follow' }
    end
  end

  def destroy
    @follow  = Follow.where(station_id: params[:id], user_id: current_user.id).first
    @station = @follow.station
    @follow.destroy
    @locals  = { :action => 'add', :id => @station.id, :count => @station.follows_count-1, :changed => true }

    respond_to do |format|
      format.js { render :partial => 'follow' }
    end
  end
end
