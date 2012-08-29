class SharesController < ApplicationController
  before_filter :authenticate_user!

  def create
    @share = Share.create(params[:share])
  end
end
