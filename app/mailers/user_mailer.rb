class UserMailer < ActionMailer::Base
  default :from => "dontreply@2u.fm"

  def follow_email(user, followee)
    @follower = user
    @followee = followee
    @unsubscribe_type = 'follow'
    set_unsubscribe_key(@followee)
    mail(to: @followee.email, subject: "#{@follower.full_name} is now following you on 2u.fm") do |format|
      format.html { render 'follow' }
    end
  end

  def share_email(sender, share)
    @sender, @receiver, @song = sender, share.receiver, share.song
    set_unsubscribe_key(@receiver)
    @unsubscribe_type = 'share'
    mail(to: @receiver.email, subject: "#{sender.full_name} sent you a song on 2u.fm") do |format|
      format.html { render 'share' }
    end
  end

  private

  def set_unsubscribe_key(user)
    @unsubscribe_key = user.confirmation_token
  end
end