class SharesController < ApplicationController
  before_filter :authenticate_user!

  def create
    @share = Share.new(sender_id: current_user.id, receiver_id: params[:receiver], song_id: params[:song])

    if @share.save!
      head 200
    else
      head 500
    end
  end
end
