module BlogsHelper
  def blog_follow_unfollow(id)
    if user_signed_in? and current_user.has_favorite_blog?(id)
      render :partial => 'blogs/favorite_remove', :locals => { :id => id }
    else
      render :partial => 'blogs/favorite_add', :locals => { :id => id }
    end
  end
end
