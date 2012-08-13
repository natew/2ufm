class UserMailer < ActionMailer::Base
  default :from => "dontreply@2u.fm"

  def welcome_email(user)
    @user    = user
    activate = Digest::SHA1.hexdigest(user.email + '328949126')
    @url     = "http://2u.fm/activate/#{@user.id}/#{activate}"

    mail(:to => "#{user.username} <#{user.email}>",
         :subject => "Welcome to 2u.fm!  Please activate your new account") do |format|
      format.html { render 'welcome' }
    end
  end

  def reset_email(user)
      @user    = user
      @reset   = Digest::SHA1.hexdigest(Time.now.to_s + '328949126')
      @user.password = @reset
      if @user.save!
        mail(:to => "#{user.username} <#{user.email}>",
             :subject => "Your 2u.fm Account Password Has Been Reset") do |format|
          format.html { render 'reset' }
        end
      end
    end

  def activation_email(user)
    @user    =  user
    mail(:to => user.email,
         :subject => "Your 2u.fm account is activated!") do |format|
      format.html { render 'activation' }
    end
  end
end