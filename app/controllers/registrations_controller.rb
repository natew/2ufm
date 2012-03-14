class RegistrationsController < Devise::RegistrationsController
	def new
		respond_to do |format|
			resource = build_resource({})
      format.html { super }
      format.js { render :layout => false }
    end
	end

	def create
		super
	end

	def update
		super
	end
end
