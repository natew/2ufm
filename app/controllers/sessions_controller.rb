class SessionsController < Devise::SessionsController
	def new
		respond_to do |format|
      format.html { super }
    end
	end

	def create
		super

    redirect_to :back
	end
end
