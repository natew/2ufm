class MainController < ApplicationController
  def index
    @blogs = Blog.page(params[:page]).per(10)
  end
end
