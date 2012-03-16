class ApplicationController < ActionController::Base
  protect_from_forgery
  
  before_filter :set_pagination_vars

  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end
  
  private

  def get_html(url)
    begin
      Nokogiri::HTML(open(url))
    rescue
      logger.error "Error opening url #{url}"
      false
    end
  end

  def fetch_url(url)
    open(url) do |h|
      final_uri = h.base_uri
    end
    final_uri
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
