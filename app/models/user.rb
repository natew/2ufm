class User < ActiveRecord::Base
  include AttachmentHelper
  include SlugExtensions

  ROLES = %w[admin blogowner user]

  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :username, :avatar, :login, :email, :password, :password_confirmation, :remember_me, :role, :provider, :uid, :bio, :full_name, :avatar_remote_url, :location

  # Virtual attribute for authenticating by either username or email
  # This is in addition to a real persisted field like 'username'
  attr_accessor :login

  has_one  :station, :dependent => :destroy
  has_many :activities, :dependent => :destroy
  has_many :follows
  has_many :stations, :through => :follows
  has_many :songs, :through => :stations, :extend => SongExtensions
  has_many :listens
  has_many :shares, :foreign_key => :receiver_id

  has_attachment :avatar, styles: { original: ['300x300#', :jpg], medium: ['128x128#', :jpg], small: ['64x64#', :jpg] }, :s3 => Yetting.s3_enabled
  has_attachment :cover, styles: { medium: ['900x300^'] } # ^ means preserve aspect ratio

  acts_as_url :username, :url_attribute => :slug, :allow_duplicates => false

  before_create :make_station, :set_station_slug, :set_station_id
  after_update :update_station_title
  before_validation :get_remote_avatar, :if => :avatar_url_provided?
  validates_presence_of :avatar_remote_url, :if => :avatar_url_provided?, :message => 'is invalid or inaccessible'

  validates :username, :length => 2..22, :uniqueness => true
  validates_with SlugValidator

  def to_param
    station_slug
  end

  def get_title
    title
  end

  def title
    username
  end

  def get_remote_avatar
    self.avatar = URI.parse(self.avatar_remote_url)
  end

  def avatar_url_provided?
    !self.avatar_remote_url.blank?
  end

  def following_songs(offset=0, limit=18)
    Song.user_following_songs(id, offset, limit)
  end

  def received_songs(offset=0, limit=18)
    Song.user_received_songs(id, offset, limit)
  end

  def received_songs_notifications
    Song.user_unread_received_songs(id)
  end

  def sent_songs(offset=0, limit=18)
    Song.user_sent_songs(id, offset, limit)
  end

  def get_song_broadcasts(ids)
    Broadcast.where(:song_id => ids, :station_id => station_id).map(&:song_id)
  end

  def get_song_listens(ids)
    Listen.select([:song_id, :shortcode]).where(:song_id => ids, :user_id => id).group(:song_id, :shortcode)
  end

  def get_station_follows(ids)
    Follow.where(:station_id => ids, :user_id => id).map(&:station_id)
  end

  def followers
    Station
    .joins('inner join users on users.station_id = stations.id')
    .joins('inner join follows on follows.user_id = users.id')
    .where('follows.station_id = ?', station_id)
  end

  def image
    avatar
  end

  def admin?
    role == 'admin'
  end

  def role?(type)
    role == type.to_s
  end

  def name
    username
  end

  def self.find_for_facebook_oauth(auth, signed_in_resource=nil, session=nil)
    user = User.where(:provider => auth.provider, :uid => auth.uid).first || User.find_by_email(auth.extra.raw_info.email)
    unless user
      info = auth.extra.raw_info
      user = User.create(
        username: info.username || info.name,
        full_name: info.name,
        provider: auth.provider,
        uid: auth.uid,
        email: session[:user_email] || info.email,
        password: Devise.friendly_token[0,20]
      )
      user.skip_confirmation!
      user.save!
    end
    user
  end

  def self.find_for_twitter_oauth(auth, signed_in_resource=nil, session=nil)
    user = User.where(:provider => auth.provider, :uid => auth.uid).first
    unless user
      info = auth.extra.raw_info
      user = User.create(
        username: info.screen_name,
        provider: auth.provider,
        uid: auth.uid,
        email: session[:user_email] || session[:email_address],
        location: info.location,
        bio: info.description,
        full_name: info.name,
        avatar_remote_url: info.profile_image_url,
        password: Devise.friendly_token[0,20]
      )
      user.skip_confirmation!
      user.save!
    end
    user
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
        user.email = data["email"] if user.email.blank?
      end
    end
  end

  def friends_with(user)
    # users_station = user.station_id
    # Follow.where(user_id: user.id, station_id: )
    # Follow.where(user_id: , station_id: )
  end

  def broadcasted_song?(song)
    station.broadcasts.where(:song_id => song.matching_id).exists?
  end

  def following_station?(id)
    follows.where(:station_id => id).exists?
  end

  def to_playlist_json
    self.to_json(:only => [:id, :slug, :name])
  end

  def make_station
    self.create_station(title:username)
  end

  def set_station_id
    self.station_id = station.id
  end

  protected

  def update_station_title
    self.station.title = username if self.username_changed?
    self.station.save
  end

  # Devise override for logins
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    login = conditions.delete(:login)
    where(conditions).where(["lower(username) = :value OR lower(email) = :value", { :value => login.downcase }]).first
  end

  # Attempt to find a user by it's email. If a record is found, send new
   # password instructions to it. If not user is found, returns a new user
   # with an email not found error.
   def self.send_reset_password_instructions(attributes={})
     recoverable = find_recoverable_or_initialize_with_errors(reset_password_keys, attributes, :not_found)
     recoverable.send_reset_password_instructions if recoverable.persisted?
     recoverable
   end

   def self.find_recoverable_or_initialize_with_errors(required_attributes, attributes, error=:invalid)
     (case_insensitive_keys || []).each { |k| attributes[k].try(:downcase!) }

     attributes = attributes.slice(*required_attributes)
     attributes.delete_if { |key, value| value.blank? }

     if attributes.size == required_attributes.size
       if attributes.has_key?(:login)
          login = attributes.delete(:login)
          record = find_record(login)
       else
         record = where(attributes).first
       end
     end

     unless record
       record = new

       required_attributes.each do |key|
         value = attributes[key]
         record.send("#{key}=", value)
         record.errors.add(key, value.present? ? error : :blank)
       end
     end
     record
   end

   def self.find_record(login)
     where(["username = :value OR email = :value", { :value => login }]).first
   end
end
