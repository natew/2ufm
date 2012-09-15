class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :do_page_request
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

  private

  def do_page_request
    return head 204 unless defined? request.headers['HTTP_ACCEPT']
    logger.debug 'ACCEPT: ' + request.headers['HTTP_ACCEPT']
    if request.headers['HTTP_ACCEPT'] =~ /text\/page/i
      id = params[:id]
      if id == '0'
        @p_station = Station.newest
        @p_songs = Song.playlist_order_published
      elsif id == '1'
        @p_station = Station.popular
        @p_songs = Song.playlist_order_trending
      elsif id == '2'
        @p_station = Station.trending
        @p_songs = Song.playlist_order_trending
      elsif id == '3'
        dont_paginate = true
        @p_station = Station.current_user_station
        @p_songs = current_user.following_songs(params[:p].to_i * Yetting.per, Yetting.per)
      else
        @p_station = Station.find_by_slug(id)
        @p_songs = @p_station.songs.playlist_order_broadcasted
      end

      @p_songs = @p_songs.limit_page(params[:p]) unless dont_paginate

      if @p_songs.count > 0
        render :partial => 'stations/playlist', :locals => { :station => @p_station, :songs => @p_songs, :partial => true }
      else
        head 204
      end
    end
  end

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
