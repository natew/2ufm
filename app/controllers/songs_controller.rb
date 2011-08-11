class SongsController < ApplicationController
  def index
    @posts = Song.page(params[:page]).per(10)
  end
  
  def show
    @post = Song.find(params[:id])
  end
end
