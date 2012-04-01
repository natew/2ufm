class SessionsController < Devise::SessionsController
	def new
		respond_to do |format|
      format.html { super }
    end
	end

	def create
		super
	end
end
