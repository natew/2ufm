class SessionsController < Devise::SessionsController
	def new
		respond_to do |format|
      format.html { super }
      format.js { render :layout => false }
    end
	end

	def create
		super
	end
end
