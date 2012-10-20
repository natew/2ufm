class ListensController < ApplicationController
  def show
    @listen = Listen.find_by_shortcode(params[:id])

    controller_name = 'StationsController'

    # Render different controller
    controller = (controller_name).constantize.new
    controller.request = @_request
    controller.response = @_response
    controller.show
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
