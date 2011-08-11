class PostsController < ApplicationController
  def index
    @posts = Post.page(params[:page]).per(10)
  end
  
  def show
    @post = Post.find(params[:id])
    @songs = @post.songs
  end
end
