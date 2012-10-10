class ListensController < ApplicationController
  def show
    listen = Listen.find_by_shortcode(params[:id])
    @song  = Song.find(listen.song_id)
    @user  = User.find(listen.user_id) if listen.has_user?
    sep    = listen.url =~ /\?/ ? '&' : '?'
    @go    = "http://#{request.host_with_port}#{listen.url}#{sep}play=true&song=#{listen.song_id}"

    render :show, layout: false

    # TODO: Replace the js redirect method to not use redirects
    # WHY: Because someone who visits this URL may want to re-share it again and wont want the ugly URL
    # HOW: Store controller, action, params into the listens rather than url, then just call this here:
    # render_component :controller=> 'different', :action => 'action', :params => params
  end

  def create
    @listen = Listen.new(
      params[:listen].merge!({
        user_id: user_signed_in? ? current_user.id : nil
      })
    )

    respond_to do |format|
      if @listen.save
        format.js
      else
        format.js { render text: @listen.save!, status: 403 }
      end
    end
  end
end
