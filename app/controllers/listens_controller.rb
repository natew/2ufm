class ListensController < ApplicationController
  def show
    @listen = Listen.find_by_shortcode(params[:id])
    route = Rails.application.routes.recognize_path(@listen.url)

    params[:id] = route[:id]
    params[:listen_song_id] = @listen.song_id
    params[:listen] = @listen.to_json
    params[:route] = url_for(route)

    # Render controller
    controller_name = "#{route[:controller]}_controller".camelize.constantize
    controller = controller_name.new
    controller.request = @_request
    controller.response = @_response
    controller.params = params
    controller.send(route[:action])
    render :text => controller.response.body
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
