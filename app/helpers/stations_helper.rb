module StationsHelper
  def station_follow_unfollow(id)
    if user_signed_in? and current_user.has_favorite_station?(id)
      render :partial => 'stations/favorite_remove', :locals => { :id => id }
    else
      render :partial => 'stations/favorite_add', :locals => { :id => id }
    end
  end
end
