class ListensController < ApplicationController  
  def show
    listen = Listen.find_by_shortcode(params[:id])
    @song  = Song.find(listen.song_id)
    @user  = User.find(listen.user_id)
    @go    = "http://#{request.host_with_port}\#!#{listen.url}?play=true&song=#{listen.song_id}&t=#{listen.time}"
    
    render :show, :layout => false
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
