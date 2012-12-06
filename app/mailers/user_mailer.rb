class UserMailer < ActionMailer::Base
  default :from => "\"2u.fm\" <noreply@2u.fm>"

  def follow(user, followee)
    return if !followee.privacy.mail_follows# or followee.privacy.receives_digests
    @follower = user
    @followee = followee
    @unsubscribe_type = 'follow'
    set_unsubscribe_key(@followee)
    mail(to: @followee.email, subject: "#{@follower.full_name} is now following you on 2u.fm") do |format|
      format.html { render 'follow' }
    end
  end

  def share(sender, share)
    return if !share.receiver.privacy.mail_shares# or followee.privacy.receives_digests
    @sender, @receiver, @song = sender, share.receiver, share.song
    set_unsubscribe_key(@receiver)
    @unsubscribe_type = 'share'
    mail(to: @receiver.email, subject: "#{sender.full_name} sent you a song on 2u.fm") do |format|
      format.html { render 'share' }
    end
  end

  def daily_digest(user)
    @user = user
    @shares = user.shares.within_last_day
    @follows = user.follows.within_last_day

    if @shares.count or @follows.count
      date = Time.now.strftime("%b #{return_date.day.ordinalize}")
      mail(to: user.email, subject: "You're popular! Activity digest for #{date}") do |format|
        format.html { render 'daily_digest' }
      end
    end
  end

  private

  def set_unsubscribe_key(user)
    @unsubscribe_key = user.confirmation_token
  end
end