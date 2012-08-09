class UserMailer < ActionMailer::Base
  default :from => "admin@gamegum.com"

  def welcome_email(user)
    @user    = user
    activate = Digest::SHA1.hexdigest(user.email + '328949126')
    @url     = "http://gamegum.com/activate/#{@user.id}/#{activate}"

    mail(:to => "#{user.login} <#{user.email}>",
         :subject => "Welcome to GameGum!  Please activate your new account") do |format|
      format.html { render 'welcome' }
      #format.text { render 'another_template' }
    end
  end

  def reset_email(user)
      @user    = user
      @reset   = Digest::SHA1.hexdigest(Time.now.to_s + '328949126')
      @user.password = @reset
      if @user.save!
        mail(:to => "#{user.login} <#{user.email}>",
             :subject => "Your GameGum Account Password Has Been Reset") do |format|
          format.html { render 'reset' }
        end
      end
    end

  def activation_email(user)
    @user    =  user
    mail(:to => user.email,
         :subject => "Your GameGum account is activated!") do |format|
      format.html { render 'activation' }
      #format.text { render 'another_template' }
    end
  end
end