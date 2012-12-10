class ApplicationController < ActionController::Base
  include IntegersFromString
  protect_from_forgery

  before_filter :dev_rails_admin

  layout :set_layout

  if Rails.env.production?
    rescue_from Exception, :with => :render_error
    rescue_from ActiveRecord::RecordNotFound, :with => :render_not_found
    rescue_from ActionController::RoutingError, :with => :render_not_found
    rescue_from ActionController::UnknownController, :with => :render_not_found
    rescue_from ActionController::UnknownAction, :with => :render_not_found
  end

  def sign_in_and_redirect(resource_or_scope, *args)
    options  = args.extract_options!
    scope    = Devise::Mapping.find_scope!(resource_or_scope)
    resource = args.last || resource_or_scope
    sign_in(scope, resource, options)
    redirect_to after_sign_in_path_for(resource) || '/feed'
  end

  def not_found
    render_not_found(nil)
    @not_found = true
  end

  def render_not_found(exception)
    set_layout
    logger.error exception
    render template: 'errors/404', status: 404 unless @not_found
  end

  def render_error(exception)
    set_layout
    logger.error "500 Internal Server Error"
    logger.error exception
    render template: 'errors/500', status: 500 unless @not_found
  end

  def is_admin?
    user_signed_in? and current_user.is_admin?
  end

  def render_page(opts)
    opts    = { page_request: true, already_limited: false, has_title: false }.merge(opts)
    opts[:songs] ||= opts[:station].songs.playlist_broadcasted
    opts[:songs]   = opts[:songs].limit_page(params[:p]) unless opts[:already_limited]

    if opts[:songs].length > 0
      self.formats = [:html]
      render partial: 'stations/playlist', locals: opts
    else
      head 204
    end
  end

  def affiliate_searchable(string)
    URI.encode(string.gsub(/[\(\[\{].*[\)\]\}]/i, '').strip)
  end

  private

  def dev_rails_admin
    return unless Rails.env.development? && request.path =~ /^\/admin\//
    RailsAdmin::Config.reset
    load 'config/initializers/rails_admin.rb'
  end

  def set_layout
    if request.headers['X-PJAX']
      request.headers['X-PJAX-FULL'] ? 'full' : 'single'
    else
      'application'
    end
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
