class Genre < ActiveRecord::Base
  has_and_belongs_to_many :blogs
  has_and_belongs_to_many :users
  has_and_belongs_to_many :artists

  acts_as_url :name, :url_attribute => :slug

  validates :name, presence: true, uniqueness: true

  before_create :map_name

  scope :active, where(active: true)
  scope :not_active, where(active: false)
  scope :ordered, order('name')
  scope :users, lambda { |user| joins(:users).where('users.id = ?', user.id) }
  scope :not_users, lambda { |user| joins("left join genres_users on genres_users.genre_id = genres.id and genres_users.user_id = '#{user.id}'").where('genres_users.user_id is null') }
  scope :for_user, lambda { |user| select('genres.*, genres_users.user_id as has_genre').joins("left join genres_users on genres_users.genre_id = genres.id and genres_users.user_id = '#{user.id}'") }

  attr_accessible :name, :blog_ids, :includes_remixes, :active

  ALTERNATIVE_NAMES = {
    'drum and bass' => 'Drum & Bass',
    'electronic' => 'Electro',
    'r&b' => 'R&B'
  }

  def to_param
    slug
  end

  def get_title
    name
  end

  def map_name
    self.name = ALTERNATIVE_NAMES[name] if ALTERNATIVE_NAMES[name]
  end

  def self.map_name(name)
    ALTERNATIVE_NAMES[name] || name
  end

  def self.artists_genres_list(ids)
    Hash[*
      Station
        .has_songs(1)
        .where(artist_id: ids)
        .select("stations.artist_id as id, string_agg(genres.name, ', ') as artist_genres")
        .joins('inner join artists on artists.id = stations.artist_id')
        .joins('inner join artists_genres on artists_genres.artist_id = artists.id')
        .joins("inner join genres on genres.id = artists_genres.genre_id")
        .group('stations.artist_id')
        .map{ |s| [s.id, s.artist_genres] }.flatten
    ]
  end
end
