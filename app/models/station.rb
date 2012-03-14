class Station < ActiveRecord::Base  
  include AttachmentHelper

  has_and_belongs_to_many :genres
  belongs_to :user
  belongs_to :blog
  belongs_to :artist
  has_many   :broadcasts, :dependent => :destroy
  has_many   :songs, :through => :broadcasts, :extend => SongExtensions
  has_many   :follows
  has_many   :artists, :through => :songs, :uniq => true
  has_many   :blogs, :through => :songs, :uniq => true

  acts_as_url :title, :url_attribute => :slug, :sync_url => true

  validates :title, presence: true

  # Whitelist mass-assignment attributes
  attr_accessible :title, :description

  def to_param
    url
  end

  def self.popular_station
    p = Station.new(:id => 1)
    p.songs = Song.order(:rank).playlist_order_published
    p
  end
  
  def self.new_station
    find(3)
  end

  def to_playlist_json
    # TODO image from parent
    self.to_json(:only => [:id, :slug, :name])
  end
  
  def has_songs?
    songs.size > 0
  end
  
  def song_exists?(song_id)
    Broadcast.where('song_id = ? and station_id = ?', song_id, id).exists?
  end
end
