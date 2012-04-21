class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :set_pagination_vars, :get_counts
  layout :set_layout

  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end

  private

  def set_layout
    if request.headers['X-PJAX']
      false
    else
      'application'
    end
  end

  def get_counts
    @count = {
      :blogs => Rails.cache.fetch(:blogs_count, :expires_in => 24.hours) { Blog.count },
      :songs => Rails.cache.fetch(:songs_count, :expires_in => 30.minutes) { Song.count },
      :users => Rails.cache.fetch(:users_count, :expires_in => 1.hour) { User.count }
    }
  end

  def set_pagination_vars
    @per = {
      :station => 10
    }
  end

  def authenticate_user!
    session[:return_to] = request.fullpath # need to upadte for path.js
    super
  end

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || session[:return_to]
    session[:return_to] = nil
  end

  # Overwriting the sign_out redirect path method
  def after_sign_out_path_for(resource_or_scope)
    root_path
  end
end
