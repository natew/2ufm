class ApplicationController < ActionController::Base
  protect_from_forgery
  
  before_filter :set_pagination_vars
  
  private
  
  def set_pagination_vars
    @per = {
      :station => 10
    }
  end
  
  # Overwriting the sign_out redirect path method
  def after_sign_out_path_for(resource_or_scope)
    root_path
  end
end
