class SharesController < ApplicationController
  before_filter :authenticate_user!

  def inbox
    @inbox_station = Station.current_user_inbox_station
    @inbox_songs = current_user.received_songs
    @has_songs = true if @inbox_songs.size > 0
  end

  def outbox
    @outbox_station = Station.current_user_outbox_station
    @outbox_songs = current_user.sent_songs
    @has_songs = true if @outbox_songs.size > 0
  end

  def create
    @share = Share.new(sender_id: current_user.id, receiver_id: params[:receiver_id], song_id: params[:song_id])

    if @share.save!
      head 200
    else
      head 500
    end
  end
end
