class User < ActiveRecord::Base
  include AttachmentHelper
  include SlugExtensions
  include IntegersFromString

  ROLES = %w[admin blogowner dluser user]
  STATION_TYPES = %w[user blog artist]

  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable,
         :allow_unconfirmed_access_for => 1.day,
         :reconfirmable => true

  serialize :last_playlist

  # Setup accessible (or protected) attributes for your model
  attr_accessible :preference_attributes, :username, :avatar, :login, :email, :password, :password_confirmation, :remember_me, :role, :provider, :uid, :bio, :full_name, :avatar_remote_url, :location, :oauth_token, :gender, :facebook_id, :first_time, :slug, :last_playing_page, :last_playlist_id, :last_playlist

  # Virtual attribute for authenticating by either username or email
  # This is in addition to a real persisted field like 'username'
  attr_accessor :login

  has_one  :preference, :dependent => :destroy
  accepts_nested_attributes_for :preference

  has_one  :station, :dependent => :destroy
  # has_many :activities, :dependent => :destroy
  has_many :follows
  has_many :stations, :through => :follows
  has_many :songs, :through => :stations, :extend => SongExtensions
  has_many :listens
  has_many :shares, :foreign_key => :receiver_id
  has_and_belongs_to_many :genres

  scope :with_preference, -> { joins(:preference) }

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
  before_validation :get_remote_avatar, if: :avatar_url_provided?
  validates_presence_of :avatar_remote_url, if: :avatar_url_provided?, message: 'is invalid or inaccessible'

  validates :full_name, presence: true, length: 4..120
  # validates_format_of :full_name, with: /[a-zA-Z\-]+ [a-zA-Z\-]+/i, message: 'Invalid characters'
  validates :username, length: 2..22, uniqueness: true
  validates_format_of :username, with: /[a-zA-Z0-9_\-]+/i, message: 'Invalid characters'
  validates_with SlugValidator

  rails_admin do
    list do
      field :full_name
      field :username
      field :sign_in_count
    end
  end

  def to_param
    station_slug
  end

  def get_title
    title
  end

  def title
    username
  end

  def receives_digests
    preference.digests != "none"
  end

  def mail_follows
    preference.mail_follows and !receives_digests
  end

  def mail_shares
    preference.mail_shares and !receives_digests
  end

  def get_remote_avatar
    self.avatar = URI.parse(self.avatar_remote_url)
    self.avatar_remote_url = nil
  end

  def avatar_url_provided?
    !self.avatar_remote_url.blank?
  end

  def notifications_count
    received_songs_notifications
  end

  def received_songs(page)
    page ||= 1
    Song.joins(:shares).where('shares.receiver_id = ?', id).playlist_received.limit(Yetting.per).offset((page.to_i - 1) * Yetting.per)
  end

  def sent_songs(page)
    page ||= 1
    Song.joins(:shares).where('shares.sender_id = ?', id).playlist_sent.limit(Yetting.per).offset((page.to_i - 1) * Yetting.per)
  end

  def following_songs(type, page=1, single=false)
    if true #single
      Song.user_following_songs(type, id, (page.to_i - 1) * Yetting.per, Yetting.per)
    else
      Song.user_following_songs(id, 0, page.to_i)
    end
  end

  def received_songs_notifications
    Song.user_unread_received_songs(id)
  end

  def get_song_broadcasts(ids)
    Broadcast.where(:song_id => ids, :station_id => station_id).map(&:song_id)
  end

  def get_song_listens(options)
    like_url = options[:url].gsub(/\?.*/,'') + '%'
    Listen.select([:song_id, :shortcode]).where(song_id: options[:songs], user_id: id).where('listens.url ILIKE (?)', like_url).group(:song_id, :shortcode)
  end

  def get_station_follows(ids)
    Follow.where(:station_id => ids, :user_id => id).map(&:station_id)
  end

  def get_friend_broadcasts(ids)
    friends = {}
    Song
      .select("songs.id, string_agg(u.full_name, ', ') as friend_names")
      .where('songs.id in (?)', ids)
      .where('me.id = ?', id)
      .group('songs.id')
      .joins('inner join broadcasts b on b.song_id = songs.id')
      .joins('inner join stations s on s.id = b.station_id')
      .joins('inner join users u on u.station_slug = s.slug')
      .joins('inner join follows f on f.station_id = s.id')
      .joins('inner join users me on me.id = f.user_id')
      .each do |song|
        friends[song.id] = song.friend_names if song.friend_names
      end

    friends
  end

  def feed_station(type)
    Station.new(id: integers_from_string("#{station.id}#{username}#{type}"), title: "#{username}'s feed", slug: "#{slug}-feed")
  end

  def store_playlist(playlist)
    if last_playlist_id != playlist[:id]
      self.update_attributes({
        last_playing_page: playlist[:page],
        last_playlist_id: playlist[:id],
        last_playlist: playlist[:data]
      })
    end
  end

  def followers
    Station
      .joins('inner join users on users.station_id = stations.id')
      .joins('inner join follows on follows.user_id = users.id')
      .where('follows.station_id = ?', station_id)
  end

  def following(type)
    return nil unless STATION_TYPES.include? type
    self.stations.where("stations.#{type}_id is not null")
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

  def first_name
    full_name.split(' ')[0] if full_name
  end

  def name
    username
  end

  def facebook_friends
    if oauth_token
      begin
        friends = Koala::Facebook::API.new(oauth_token).get_connections('me', 'friends')
        friend_ids = friends.map { |friend| friend['id'] }
        User.where('users.facebook_id in (?)', friend_ids)
      rescue
        nil
      end
    end
  end

  def self.find_for_facebook_oauth(auth, signed_in_resource=nil, session=nil)
    logger.info auth
    user = User.where(:provider => auth.provider, :uid => auth.uid).first || User.find_by_email(auth.extra.raw_info.email)
    if user
      user.update_attributes(oauth_token: auth.credentials.token) if auth.credentials.token != user.oauth_token
    else
      info = auth.extra.raw_info
      user = User.new(
        username: info.username || info.name,
        full_name: info.name,
        provider: auth.provider,
        uid: auth.uid,
        email: info.email,
        avatar_remote_url: auth.info.image,
        password: Devise.friendly_token[0,20],
        oauth_token: auth.credentials.token,
        gender: info.gender,
        location: info.location ? info.location.name : '',
        facebook_id: info.id
      )
      user.skip_confirmation!
      user.save!
    end
    user
  end

  def update_for_facebook_oauth(auth)
    info = auth.extra.raw_info
    self.skip_confirmation!
    self.update_attributes(
      full_name: info.name,
      provider: auth.provider,
      uid: auth.uid,
      avatar_remote_url: auth.info.image,
      oauth_token: auth.credentials.token,
      gender: info.gender,
      location: info.location ? info.location.name : '',
      facebook_id: info.id
    )
    self
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
        user.email = data["email"] if user.email.blank?
      end
    end
  end

  def set_genres(genres_list)
    self.genres.destroy_all
    added = []
    genres_list.each do |add_genre|
      genre = Genre.find(add_genre)
      self.genres << genre if genre
      added.push genre.id
    end
    self.updated_at = Time.now
    self.save
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
    self.create_station(title:username, online:Time.now)
  end

  def make_privacy
    self.create_preference
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
        record.errors.add(key, value.present? ? error : 'not found')
      end
    end
    record
  end

  def self.find_record(login)
    where(["username = :value OR email = :value", { :value => login }]).first
  end
end
