class User < ActiveRecord::Base
  include AttachmentHelper
  include SlugExtensions

  ROLES = %w[admin blogowner dluser user]

  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable,
         :allow_unconfirmed_access_for => 1.day,
         :reconfirmable => true

  # Setup accessible (or protected) attributes for your model
  attr_accessible :username, :avatar, :login, :email, :password, :password_confirmation, :remember_me, :role, :provider, :uid, :bio, :full_name, :avatar_remote_url, :location, :oauth_token, :gender, :facebook_id, :first_time

  # Virtual attribute for authenticating by either username or email
  # This is in addition to a real persisted field like 'username'
  attr_accessor :login

  has_one  :station, :dependent => :destroy
  has_one  :privacy, :dependent => :destroy
  has_many :activities, :dependent => :destroy
  has_many :follows
  has_many :stations, :through => :follows
  has_many :songs, :through => :stations, :extend => SongExtensions
  has_many :listens
  has_many :shares, :foreign_key => :receiver_id
  has_and_belongs_to_many :genres

  has_attachment :avatar,
    styles: {
      original: ['300x300#', :jpg],
      medium: ['128x128#', :jpg],
      small: ['64x64#', :jpg]
    },
    s3: Yetting.s3_enabled

  acts_as_url :username, sync_url: true, url_attribute: :slug, allow_duplicates: false

  before_create :make_station, :make_privacy, :set_station_slug, :set_station_id
  before_update :update_station_title
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

  def feed_station
    Station.new(id: -station.id, title:"#{username}'s feed", slug:"#{slug}-feed")
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

  def facebook_friends
    friends = Koala::Facebook::API.new(oauth_token).get_connections('me', 'friends')
    friend_ids = friends.map { |friend| friend['id'] }
    User.where('users.facebook_id in (?)', friend_ids)
  end

  def self.find_for_facebook_oauth(auth, signed_in_resource=nil, session=nil)
    logger.info auth
    user = User.where(:provider => auth.provider, :uid => auth.uid).first || User.find_by_email(auth.extra.raw_info.email)
    unless user
      info = auth.extra.raw_info
      user = User.create(
        username: info.username || info.name,
        full_name: info.name,
        provider: auth.provider,
        uid: auth.uid,
        email: info.email,
        avatar_remote_url: auth.info.image,
        password: Devise.friendly_token[0,20],
        oauth_token: auth.credentials.token,
        gender: info.gender,
        location: info.location.name,
        facebook_id: info.id
      )
      user.skip_confirmation!
      user.save!
    else
      user.update_attributes(oauth_token: auth.credentials.token) if auth.credentials.token != user.oauth_token
    end
    user
  end

  def update_for_facebook_oauth(auth)
    info = auth.extra.raw_info
    self.update_attributes(
      full_name: info.name,
      provider: auth.provider,
      uid: auth.uid,
      avatar_remote_url: auth.info.image,
      oauth_token: auth.credentials.token,
      gender: info.gender,
      location: info.location.name,
      facebook_id: info.id
    )
    self.skip_confirmation!
    self.save!
    self
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

  def set_genres(genres_list)
    self.genres.destroy_all
    added = []
    genres_list.each do |add_genre|
      genre = Genre.find(add_genre)
      self.genres << genre if genre
      added.push genre.id
    end
    added
  end

  def broadcasted_song?(song)
    station.broadcasts.where(:song_id => song.matching_id).exists?
  end

  def following_station?(id)
    follows.where(:station_id => id).exists?
  end

  def is_following?(user)
    follows.where(station_id: user.station_id).exists?
  end

  def to_playlist_json
    self.to_json(:only => [:id, :slug, :name])
  end

  def make_station
    self.create_station(title:username)
  end

  def make_privacy
    self.create_privacy
  end

  def set_station_id
    self.station_id = station.id
  end

  def can_download?
   role =~ /dluser|admin/
  end


  protected


  def update_station_title
    if self.username_changed?
      self.station.title = username
      self.station.save
    end
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
