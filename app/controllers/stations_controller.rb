class StationsController < ApplicationController

  def index
    @stations = Station.order('created_at desc').page(params[:page]).per(9)

    respond_to do |format|
      format.html
    end
  end

  def show
    @station = Station.find_by_slug(params[:id]) || not_found
    @artists = @station.artists.limit(20)
    @primary = @station

    respond_to do |format|
      format.html
    end
  end
end
