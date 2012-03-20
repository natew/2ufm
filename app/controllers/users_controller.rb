class UsersController < ApplicationController
  before_filter :load_user, :except => [:create, :new, :activate, :index, :account]

  def index
    @users = User.page(params[:page]).per(25)

    respond_to do |format|
      format.html
      format.js { render :layout => false }
    end
  end

  def new
    if request.xml_http_request?
      unless params[:login].nil?
        if User.count(:conditions => { :login => params[:login] }).zero?
          render :text => 'Username <span>available</span>'
        else
          render :text => 'Username <span>already taken</span>'
        end
      end
    end
  end

  def show
    @plays = Listen.select('listens.created_at, listens.url, songs.name, songs.slug, users.username, users.slug').joins(:song,:user).where(:user_id => @user.id).limit(12)
    @song = Song.new

    respond_to do |format|
      format.html
      format.js { render :layout => false }
      format.rss { render :layout => false }
    end
  end

  def create
    cookies.delete :auth_token
    @user = User.new(params[:user])
    @user.role = 'user'

    if @user.save
      self.current_user = @user
      redirect_to @user
      UserMailer.welcome_email(@user).deliver
      flash[:notice] = "Welcome!"
    else
      render :action => 'new'
      flash[:notice] = "Error signing up!"
    end
  end

  def activate
    @user = User.find(params[:id].to_i)

    if @user.email_confirmed?
      @message = 'Account has already been activated!'
    else
      verify = Digest::SHA1.hexdigest(@user.email + '328949126')

      if verify == params[:key]
        if @user.update_attribute(:email_confirmed, true)
          @message = 'Congrats!  Your account has been activated'
        else
          @message = 'Error activating account.  Please contact support.'
        end
      else
        @message = 'Sorry!  Your verification key does not match' + verify
      end
    end
  end

  def update
    if current_user.update_attributes(params[:user])
      redirect_to 'account/profile', :notice => 'Updated successfully'
    else
      render :action => 'profile'
    end
  end

  private

  def load_user
    @user = User.find_by_slug(params[:id])
  end
end
