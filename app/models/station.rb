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

  scope :blog_station, where('blog_id is not NULL')

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

  def image
    if !blog_id.nil?
      blog.image
    elsif !artist_id.nil?
      artist.image
    elsif !user_id.nil?
      user.image
    end
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
    self.to_json(:only => [:id, :slug, :title], :include => {
      :songs => {
        :only => [
          :artist_name,
          :id,
          :name,
          :url,
          :image
        ]
      }
    })
  end

  def has_songs?
    songs.size > 0
  end

  def song_exists?(song_id)
    Broadcast.where('song_id = ? and station_id = ?', song_id, id).exists?
  end
end
