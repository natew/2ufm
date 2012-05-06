class Station < ActiveRecord::Base
  has_and_belongs_to_many :genres
  belongs_to :user
  belongs_to :artist
  belongs_to :blog
  has_many   :broadcasts, :dependent => :destroy
  has_many   :songs, :through => :broadcasts, :extend => SongExtensions
  has_many   :follows
  has_many   :artists, :through => :songs, :uniq => true
  has_many   :blogs, :through => :songs, :uniq => true

  # Whitelist mass-assignment attributes
  attr_accessible :id, :description, :title

  def user_broadcasts
    broadcasts.where(:parent => 'user')
  end

  def self.popular_station(opts={})
    p = Station.new(:id => 1, :title => 'Popular Today')
    p.songs = Song.playlist_order_rank.limit(opts[:limit] || 12)
    p
  end

  def self.new_station(opts={})
    p = Station.new(:id => 0, :title => 'Newest')
    p.songs = Song.playlist_order_published.limit(opts[:limit] || 12)
    p
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
