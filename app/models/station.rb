class Station < ActiveRecord::Base

  TIME_UNTIL_OFFLINE = 6.minutes

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

  # Order
  scope :order_random, order('random() desc')

  # Select
  scope :shelf, select('stations.slug, stations.title, stations.songs_count, stations.id, stations.blog_id, stations.user_id, stations.artist_id, stations.broadcasts_count, stations.follows_count')
  scope :distinct, select('DISTINCT ON (stations.blog_id) stations.*')
  scope :select_for_navbar, select('users.full_name as full_name, stations.id, stations.user_id, stations.title, stations.slug')
  scope :ordered_online, order('stations.online desc')

  # Where
  scope :online, lambda { where('stations.online >= ?', Time.now - TIME_UNTIL_OFFLINE) }
  scope :not_online, lambda { where('stations.online < ?', Time.now - TIME_UNTIL_OFFLINE) }
  scope :join_songs_on_blog, joins('inner join songs on songs.blog_id = stations.blog_id')

  # Has
  scope :has_parent, where([has_blog, has_artist, has_user].join(' OR '))
  scope :has_songs, lambda { |count| where('stations.broadcasts_count > ?', count - 1) }
  scope :has_image, lambda { |parent, image_name| joins(parent).where("#{parent.to_s.pluralize}.#{image_name}_updated_at is not null") }
  scope :has_blog_image, has_image(:blog, 'image')
  scope :has_user_image, has_image(:user, 'avatar')
  scope :has_artist_image, has_image(:artist, 'image')

  # Joins
  scope :with_user, joins(:user)
  scope :with_genres, joins(:genres)
  scope :with_blogs_genres,
    joins('inner join blogs_genres on blogs_genres.blog_id = blogs.id')
    .joins('inner join genres on genres.id = blogs_genres.genre_id')
  scope :blog_genre, lambda { |genre_name| with_blogs_genres.where(genres: { name: genre_name }) }

  # Types
  scope :blog_station, where(has_blog)
  scope :artist_station, where(has_artist)
  scope :user_station, where(has_user)
  scope :promo_station, where(:promo => true)

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

  def self.fake_station
    fake({})
  end

  def self.fake(options)
    Station.new(id: (options[:id] || SecureRandom.random_number(100000000)), title: options[:title] || '', slug: options[:slug || ''])
  end

  def self.trending
    fake(id: 2, title: 'Trending Songs')
  end

  def self.popular
    fake(id: 1, title: 'Popular Songs')
  end

  def self.newest
    fake(id: 0, title: 'Newest Songs')
  end

  def self.artists_from_genre(genre, page)
    artists = Station
      .has_songs(1)
      .joins('inner join artists on artists.id = stations.artist_id')
      .joins('inner join artists_genres on artists_genres.artist_id = artists.id')
      .joins("inner join genres on genres.id = artists_genres.genre_id")
      .where(genres: { slug: genre })
      .order('stations.songs_count desc')
      .page(page)
      .per(Yetting.per)

    artists_genres = Genre.artists_genres_list(artists.map(&:artist_id))

    artists.each do |station|
      station.content = artists_genres[station.artist_id]
    end

    artists
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
