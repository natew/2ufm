class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :get_suggestions, :do_page_request, :set_pagination_vars, :get_counts
  layout :set_layout

  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end

  def delayed_job_admin_authentication
    true #user_signed_in? and current_user.admin?
  end

  private

  def do_page_request
    logger.debug 'ACCEPT: ' + request.headers['HTTP_ACCEPT']
    if request.headers['HTTP_ACCEPT'] =~ /text\/page/i
      id = params[:id]
      if id == '0'
        @p_station = Station.newest
        @p_songs = Song.newest
      elsif id == '1'
        @p_station = Station.popular
        @p_songs = Song.popular
      else
        @p_station = Station.find_by_slug(id)
        @p_songs = @p_station.songs.playlist_order_broadcasted
      end

      logger.debug @p_songs.length

      if @p_songs.length > 0
        return render :partial => 'stations/playlist', :locals => { :station => @p_station, :songs => @p_songs }
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

  def get_suggestions
    @suggestions = Artist.order('random() desc').limit(3).map(&:name).join(', ')
  end

  def get_counts
    @count = {
      :blogs => Rails.cache.fetch(:blogs_count, :expires_in => 24.hours) { Blog.count },
      :songs => Rails.cache.fetch(:songs_count, :expires_in => 30.minutes) { Song.working.count },
      :users => Rails.cache.fetch(:users_count, :expires_in => 1.hour) { User.count },
      :artists => Rails.cache.fetch(:artists_count, :expires_in => 1.hour) { Artist.count }
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
