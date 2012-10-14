class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def facebook
    # You need to implement the method below in your model (e.g. app/models/user.rb)
    if user_signed_in?
      @user = current_user.update_for_facebook_oauth(request.env["omniauth.auth"])

      if !@user.facebook_id.blank?
        flash[:notice] = "Facebook successfully linked!"
        redirect_to '/authorized'
      else
        flash[:notice] = "Error linking facebook!"
        redirect_to '/'
      end
    else
      @user = User.find_for_facebook_oauth(request.env["omniauth.auth"], current_user, session)

      if @user.persisted?
        flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "Facebook"
        sign_in @user
        redirect_to '/authorized'
      else
        session["devise.facebook_data"] = request.env["omniauth.auth"]
        redirect_to new_user_registration_url
      end
    end
  end
end