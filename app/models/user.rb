class User < ActiveRecord::Base
  include AttachmentHelper

  ROLES = %w[admin blogowner user]

  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :username, :login, :email, :password, :password_confirmation, :remember_me, :role

  # Virtual attribute for authenticating by either username or email
  # This is in addition to a real persisted field like 'username'
  attr_accessor :login

  has_one  :station, :dependent => :destroy
  has_many :activities, :dependent => :destroy
  has_many :follows
  has_many :stations, :through => :follows
  has_many :songs, :through => :stations, :extend => SongExtensions

  has_attachment :avatar, styles: { original: ['300x300#'], medium: ['128x128#'], small: ['64x64#'] }

  acts_as_url :username, :url_attribute => :slug

  before_create :make_station

  validates :username, :presence => true, :length => 3..100
  validates_with SlugValidator

  def to_param
    slug
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

  def broadcasted_song?(song)
    station.broadcasts.where(:song_id => song.shared_id).exists?
  end

  def following_station?(id)
    follows.where(:station_id => id).exists?
  end

  def to_playlist_json
    self.to_json(:only => [:id, :slug, :name])
  end

  protected

  def make_station
    self.create_station(title:username)
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
