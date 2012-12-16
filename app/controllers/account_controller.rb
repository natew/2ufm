class AccountController < ApplicationController
  before_filter :authenticate_user!

  def index
    if params[:user]
      current_user.avatar.destroy if params[:avatar] and params[:avatar][:delete] == '1'

      if params[:user][:username] and params[:user][:username] != current_user.username and Station.find_by_slug(params[:user][:username])
        flash[:notice] = 'Station name taken'
      else
        current_user.update_without_password(params[:user])
        flash[:notice] = 'Updated account!'
      end
    end
  end

  def preferences
    if params[:user] and current_user.update_without_password(params[:user])
      flash[:notice] = "Updated preferences!"
    end
  end

  def edit
    return if params[:user].nil?

    # Old pass
    old_pass = params[:user][:old_password]
    params[:user].delete :old_password

    if old_pass.blank?
      current_user.update_without_password(params[:user])
      flash[:notice] = 'Updated account!'
    elsif current_user.valid_password? old_pass
      current_user.update_with_password(params[:user])
      flash[:notice] = 'Updated password!'
    else
      flash[:notice] = 'Incorrect password.'
    end
  end

end
