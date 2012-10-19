class SharesController < ApplicationController
  before_filter :authenticate_user!
  after_filter :mark_read, :only => [:inbox]

  def inbox
    @inbox_station = Station.current_user_inbox_station
    @inbox_songs = current_user.received_songs(params[:p])
    @has_songs = true if @inbox_songs.size > 0

    respond_to do |format|
      format.html
      format.page { render_page @inbox_station, @inbox_songs }
    end
  end

  def outbox
    @outbox_station = Station.current_user_outbox_station
    @outbox_songs = current_user.sent_songs(params[:p])
    @has_songs = true if @outbox_songs.size > 0

    respond_to do |format|
      format.html
      format.page { render_page @outbox_station, @outbox_songs }
    end
  end

  def create
    @share = Share.new(sender_id: current_user.id, receiver_id: params[:receiver_id], song_id: params[:song_id])

    if @share.save
      UserMailer.delay.share_email(current_user, @share)
      respond_to do |format|
        format.js
      end
    else
      render status: 500, text: @share.errors.full_messages.to_sentence
    end
  end

  private

  def mark_read
    current_user.shares.where(:read => false).update_all(:read => true)
  end
end
