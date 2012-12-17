class UserMailer < ActionMailer::Base
  default from: "\"2u.fm\" <noreply@2u.fm>"

  def follow(user, followee)
    @follower = user
    @followee = followee
    @unsubscribe_type = 'follow'
    set_unsubscribe_key(@followee)
    logger.info "erakndasndjknadklsandksandlsandkaslndsakldnaslkdnaskldnslakdnsalknd"
    logger.info from + "------------------------------"
    mail(from: from, to: @followee.email, subject: "#{@follower.full_name} is now following you on 2u.fm") do |format|
      format.html { render 'follow' }
    end
  end

  def share(sender, share)
    return unless share.receiver.preference.mail_shares and !share.receiver.receives_digests
    @sender, @receiver, @song = sender, share.receiver, share.song
    set_unsubscribe_key(@receiver)
    @unsubscribe_type = 'share'
    mail(from: from, to: @receiver.email, subject: "#{sender.full_name} sent you a song on 2u.fm") do |format|
      format.html { render 'share' }
    end
  end

  def daily_digest(user)
    @user = user
    @shares = user.shares.within_last_day
    @follows = user.follows.within_last_day

    if @shares.count or @follows.count
      date = Time.now.strftime("%b #{return_date.day.ordinalize}")
      mail(from: from, to: user.email, subject: "New Happenings on 2u.fm Today") do |format|
        format.html { render 'daily_digest' }
      end
    end
  end

  private

  def from
    "\"2u.fm\" <noreply@2u.fm>"
  end

  def set_unsubscribe_key(user)
    @unsubscribe_key = user.confirmation_token
  end
end