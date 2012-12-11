class Genre < ActiveRecord::Base
  has_and_belongs_to_many :blogs
  has_and_belongs_to_many :users

  has_many :artist_genres
  has_many :artists, :through => :artist_genres
  has_many :song_genres
  has_many :songs, :through => :song_genres

  acts_as_url :name, :url_attribute => :slug

  validates :name, presence: true, uniqueness: true

  before_create :map_name

  scope :active, where(active: true)
  scope :not_active, where(active: false)
  scope :ordered, order('name')
  scope :users, lambda { |user| joins(:users).where('users.id = ?', user.id) }
  scope :not_users, lambda { |user| joins("left join genres_users on genres_users.genre_id = genres.id and genres_users.user_id = '#{user.id}'").where('genres_users.user_id is null') }
  scope :for_user, lambda { |user| select('genres.*, genres_users.user_id as has_genre').joins("left join genres_users on genres_users.genre_id = genres.id and genres_users.user_id = '#{user.id}'") }

  scope :from_artist, where(song_genres: { source: 'artist' })
  scope :from_blog, where(song_genres: { source: 'blog' })
  scope :from_tag, where(song_genres: { source: 'tag' })
  scope :from_post, where(song_genres: { source: 'post' })


  attr_accessible :name, :blog_ids, :includes_remixes, :active
  attr_accessor :play_mode

  rails_admin do
    list do
      field :name
      field :includes_remixes
    end
  end

  ALTERNATIVE_NAMES = {
    'drum and bass' => 'Drum & Bass',
    'electronic' => 'Electro',
    'r&b' => 'R&B'
  }

  def to_param
    slug
  end

  def get_title
    play_mode ? "#{play_mode.capitalize} #{name}" : name
  end

  def map_name
    self.name = ALTERNATIVE_NAMES[name] if ALTERNATIVE_NAMES[name]
  end

  def self.map_name(name)
    ALTERNATIVE_NAMES[name] || name
  end

  def self.artist_genres_list(ids)
    Hash[*
      Station
        .has_songs(1)
        .where(artist_id: ids)
        .select("stations.artist_id as id, string_agg(genres.name, ', ') as artist_genres")
        .joins('inner join artists on artists.id = stations.artist_id')
        .joins('inner join artist_genres on artist_genres.artist_id = artists.id')
        .joins("inner join genres on genres.id = artist_genres.genre_id")
        .group('stations.artist_id')
        .map{ |s| [s.id, s.artist_genres] }.flatten
    ]
  end
end
