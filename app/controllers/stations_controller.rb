class StationsController < ApplicationController

  def index
    @featured_stations = Station.has_parent.order('created_at desc').limit(8)
    @other_stations = Station.has_parent.order('random() desc').limit(8)
    @top_stations = Station.has_parent.order('random()').limit(8)

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
