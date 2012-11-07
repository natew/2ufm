class Station < ActiveRecord::Base
  has_and_belongs_to_many :genres
  belongs_to :user
  belongs_to :artist
  belongs_to :blog
  has_many   :broadcasts, :dependent => :destroy
  has_many   :songs, :through => :broadcasts, :extend => SongExtensions
  has_many   :follows, :dependent => :destroy
  has_many   :followers, :through => :follows, :source => :station
  has_many   :artists, :through => :songs
  has_many   :blogs, :through => :songs, :uniq => true

  # Parent scrops
  has_blog = 'stations.blog_id is not NULL'
  has_artist = 'stations.artist_id is not NULL'
  has_user = 'stations.user_id is not NULL'

  # Scopes
  scope :distinct, select('DISTINCT ON (stations.blog_id) stations.*')
  scope :select_for_navbar, select('users.full_name as full_name, stations.id, stations.user_id, stations.title, stations.slug')
  scope :ordered_online, order('stations.online desc')

  scope :has_parent, where([has_blog, has_artist, has_user].join(' OR '))
  scope :has_songs, where('stations.broadcasts_count > 0')
  scope :has_image, lambda { |parent, image_name| joins(parent).where("#{parent.to_s.pluralize}.#{image_name}_content_type is not null") }
  scope :has_blog_image, has_image(:blog, 'image')
  scope :has_user_image, has_image(:user, 'avatar')
  scope :has_artist_image, has_image(:artist, 'image')

  scope :with_user, joins(:user)
  scope :with_genres, joins(:genres)

  scope :blog_station, where(has_blog)
  scope :artist_station, where(has_artist)
  scope :user_station, where(has_user)
  scope :promo_station, where(:promo => true)

  scope :online, where('online >= ?', 6.minutes.ago).ordered_online
  scope :not_online, where('online < ?', 6.minutes.ago).ordered_online
  scope :join_songs_on_blog, joins('inner join songs on songs.blog_id = stations.blog_id')

  # Whitelist mass-assignment attributes
  attr_accessible :id, :description, :title, :slug, :online
  attr_accessor :content

  # Slug
  acts_as_url :title, sync_url: true, url_attribute: :slug, allow_duplicates: false

  # Validations
  validates_with SlugValidator
  validates :slug, :uniqueness => true

  after_create :update_user_station
  after_update :update_parent_station_slug

  def to_param
    slug
  end

  def get_title
    title
  end

  def type
    if user_id
      'user'
    elsif blog_id
      'blog'
    elsif artist_id
      'artist'
    else
      'none'
    end
  end

  def user_broadcasts
    broadcasts.where(:parent => 'user')
  end

  def self.current_user_outbox_station
    Station.new(id: 5, title:'Outbox', slug:'outbox')
  end

  def self.current_user_inbox_station
    Station.new(id: 4, title:'Inbox', slug:'inbox')
  end

  def self.current_user_station
    Station.new(id: 3, title:'My Music Feed', slug:'my-station')
  end

  def self.trending(opts={})
    p = Station.new(:id => 2, :title => 'Trending Songs', :slug => 'songs')
  end

  def self.popular(opts={})
    p = Station.new(:id => 1, :title => 'Popular Songs', :slug => 'songs')
  end

  def self.newest(opts={})
    p = Station.new(:id => 0, :title => 'Newest Songs', :slug => 'songs-new')
  end

  def image
    get_parent.image
  end

  def avatar_exists?
    get_parent.avatar.exists?
  end

  def avatar(size)
    get_parent.avatar(size)
  end

  def description
    parent = get_parent
    parent.description if parent.respond_to?('description')
  end

  def to_api_json
    self.to_json(:only => [:id, :slug, :title], :include => {
      :songs => {
        :only => [
          :absolute_url,
          :artist_name,
          :blog_id,
          :blog_name,
          :id,
          :name,
          :rank,
          :url,
          :image
        ]
      }
    })
  end

  def to_playlist_json
    # TODO image from parent
    self.to_json(:only => [:id, :slug, :title])
  end

  def has_songs?
    songs.size > 0
  end

  def song_exists?(song_id)
    Broadcast.where('song_id = ? and station_id = ?', song_id, id).exists?
  end

  def update_parent_station_slug
    if get_parent
      if get_parent.station_slug != slug
        get_parent.station_slug = slug
        get_parent.save
      end
    else
      puts "No parent!"
    end
  end

  def update_user_station
    if !user_id.nil?
      user.station_id = id
      user.save
    end
  end

  def get_parent
    if !blog_id.nil?
      blog
    elsif !artist_id.nil?
      artist
    elsif !user_id.nil?
      user
    end
  end
end
