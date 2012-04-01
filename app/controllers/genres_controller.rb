class GenresController < ApplicationController
  def show
    @genre = Genre.find_by_slug(params[:id])

    respond_to do |format|
      format.html
    end
  end
end
