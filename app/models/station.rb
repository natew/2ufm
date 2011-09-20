class Station < ActiveRecord::Base  
  include AttachmentHelper

  has_and_belongs_to_many :genres
  belongs_to :user
  belongs_to :blog
  belongs_to :artist
  has_many   :broadcasts, :dependent => :destroy
  has_many   :songs, :through => :broadcasts, :extend => SongExtensions
  has_many   :follows
  
  def self.popular_station
    find(10)
  end
  
  def self.new_station
    find(11)
  end
  
  def has_songs?
    songs.size > 0
  end
  
  def song_exists?(song_id)
    Broadcast.where('song_id = ? and station_id = ?', song_id, id).exists?
  end
end
