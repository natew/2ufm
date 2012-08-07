class Broadcast < ActiveRecord::Base
  belongs_to :station, :counter_cache => true
  belongs_to :song, :primary_key => :matching_id

  validates :song_id, presence: true
  validates :station_id, presence: true
  validates :parent, presence: true
  validates :song_id, :uniqueness => {:scope => :station_id}

  scope :excluding_stations, lambda { |ids| where(['station_id NOT IN (?)', ids]) if ids.any? }
  scope :blog_broadcasts, where(:parent => 'blog')

  before_validation :set_parent, :on => :create
  before_save :update_song_rank, :update_station_timestamp
  after_create :update_counter_cache
  after_destroy :update_counter_cache

  private

  def update_song_rank
    return unless song
    song.set_rank
    song.save
  end

  # Update user_broadcasts_count on songs
  def update_counter_cache
    matching_song = Song.find(song_id)
    if matching_song
      matching_song.user_broadcasts_count = matching_song.user_broadcasts.count
      matching_song.blog_broadcasts_count = matching_song.blog_broadcasts.count
      matching_song.save
    end

    if station
      station.songs_count = station.songs.count
      station.save
    end
  end

  def set_parent
    if station.user_id
      self.parent = :user
    elsif station.artist_id
      self.parent = :artist
    elsif station.blog_id
      self.parent = :blog
    end
  end

  def update_station_timestamp
    if station
      self.station.last_broadcasted_at = Time.now
      self.station.save
    end
  end
end
