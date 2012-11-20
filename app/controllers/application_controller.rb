class ApplicationController < ActionController::Base
  include IntegersFromString
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

  def render_page(station, songs=nil, opts)
    opts    = { already_limited: false, has_title: false }.merge(opts)
    songs ||= station.songs.playlist_broadcasted
    songs   = songs.limit_page(params[:p]) unless opts[:already_limited]

    if songs.length > 0
      self.formats = [:html]
      render partial: 'stations/playlist', locals: { station: station, songs: songs, page_request: true, already_limited: opts[:already_limited], has_title: opts[:has_title] }
    else
      head 204
    end
  end

  def affiliate_searchable(string)
    URI.encode(string.gsub(/[\(\[\{].*[\)\]\}]/i, '').strip)
  end

  private

  def set_layout
    request.headers['X-PJAX'] ? 'single' : 'application'
  end

  def authenticate_user!
    session[:return_to] = request.fullpath # need to upadte for path.js
    super
  end

  def after_sign_in_path_for(resource)
    session[:return_to] || '/'
  end

  # Overwriting the sign_out redirect path method
  def after_sign_out_path_for(resource_or_scope)
    '/'
  end
end
