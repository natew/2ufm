class Broadcast < ActiveRecord::Base
  belongs_to :station, :counter_cache => true
  belongs_to :song

  validates :song_id, presence: true
  validates :station_id, presence: true
  validates :parent, presence: true
  validates :song_id, :uniqueness => {:scope => :station_id}

  scope :excluding_stations, lambda { |ids| where(['station_id NOT IN (?)', ids]) if ids.any? }
  scope :blog_broadcasts, where(:parent => 'blog')

  before_validation :set_parent, :on => :create
  after_create :delayed_update_actions
  after_destroy :delayed_update_actions

  attr_accessible :song_id, :station_id, :created_at

  # Update user_broadcasts_count on songs
  def update_counter_cache
    matching_songs = Song.where(matching_id:song_id)
    if matching_songs.length > 0
      matching_songs.update_all(
        user_broadcasts_count: song.user_broadcasts.count,
        blog_broadcasts_count: song.blog_broadcasts.count
      )
    end
  end

  def update_station_songs_count
    return unless station
    station.songs_count = station.songs.count
    station.save
  end

  def update_actions
    update_counter_cache
    update_station_songs_count
    update_song_rank
    update_station_timestamp
  end

  def delayed_update_actions
    if Rails.application.config.delay_jobs
      delay.update_actions
    else
      update_actions
    end
  end

  private

  def update_song_rank
    song = Song.find(song_id)
    if song
      song.set_rank
      song.save
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
