class RegistrationsController < Devise::RegistrationsController
	def new
		respond_to do |format|
			resource = build_resource({})
      format.html { super }
    end
	end

	def create
		super
	end

	def update
		super
	end
end
