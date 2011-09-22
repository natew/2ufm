class ListensController < ApplicationController
  before_filter :authenticate_user!, :only => [:create]
  
  def show
    listen = Listen.find_by_shortcode(params[:id])
    redirect_to "\#!#{listen.url}?play=true&song=#{listen.song_id}&t=#{listen.time}"
  end
  
  def create
    @listen = Listen.new(params[:listen])

    respond_to do |format|
      if @listen.save
        format.js { render :text => @listen.shortcode }
      else
        format.js { render :text => @listen.save!, :status => 403 }
      end
    end
  end
end
