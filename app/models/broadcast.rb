class Broadcast < ActiveRecord::Base
  belongs_to :station, :counter_cache => true
  belongs_to :song, :primary_key => :shared_id

  validates :song_id, presence: true
  validates :station_id, presence: true
  validates :parent, presence: true

  scope :excluding_stations, lambda { |ids| where(['station_id NOT IN (?)', ids]) if ids.any? }

  before_validation :set_parent, :on => :create
  before_save :update_song_rank, :update_counter_cache, :update_stations_timestamp
  after_destroy :update_counter_cache

  private

  def update_song_rank
    if song
      song.set_rank
      song.save
    end
  end

  # Update user_broadcasts_count on songs
  def update_counter_cache
    if song
      self.song.user_broadcasts_count = song.user_broadcasts.count
      self.song.save
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
      self.station.updated_at = Time.now
      self.station.save
    end
  end
end
