class ApplicationController < ActionController::Base
  protect_from_forgery

  layout :set_layout

  def sign_in_and_redirect(resource_or_scope, *args)
    options  = args.extract_options!
    scope    = Devise::Mapping.find_scope!(resource_or_scope)
    resource = args.last || resource_or_scope
    sign_in(scope, resource, options)
    redirect_to after_sign_in_path_for(resource) || '/feed'
  end

  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end

  def is_admin?
    user_signed_in? and current_user.is_admin?
  end

  def render_page(station, songs=nil, paginate=true)
    # return head 204 unless defined? request.headers['HTTP_ACCEPT']

    logger.info "paginate #{paginate}"
    songs ||= station.songs.playlist_order_broadcasted
    songs   = songs.limit_page(params[:p]) if paginate

    if songs.length > 0
      self.formats = [:html]
      render partial: 'stations/playlist', locals: { station: station, songs: songs, partial: !paginate }
    else
      head 204
    end
  end

  private

  def set_layout
    if request.headers['X-PJAX']
      'single'
    else
      'application'
    end
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
