class Station < ActiveRecord::Base  
  include AttachmentHelper

  has_and_belongs_to_many :genres
  belongs_to :user
  belongs_to :blog
  has_many   :broadcasts, :dependent => :destroy
  has_many   :songs, :through => :broadcasts, :extend => SongExtensions
  
  has_attachment :image, styles: { original: ['300x300#'], medium: ['128x128#'], small: ['64x64#'] }
  
  acts_as_url :name, :url_attribute => :slug

  def to_param
    slug
  end
  
  def self.popular_station
    find_by_slug('popular-songs')
  end
  
  def self.new_station
    find_by_slug('new-songs')
  end
  
  def has_songs?
    songs.size > 0
  end
  
  def song_exists?(song_id)
    Broadcast.where('song_id = ? and station_id = ?', song_id, id).exists?
  end
  
  def self.most_favorited(options = {})
    cols   = column_names.collect {|c| "stations.#{c}"}.join(",")
    within = options[:days] || 31
    limit  = options[:limit] || 12
    where  = " WHERE stations.created_at > '#{within.to_i.days.ago.to_s(:db)}'"
    
    Station.find_by_sql "SELECT stations.*, count(favorites.id) as favorites_count FROM stations INNER JOIN favorites on favorites.favorable_id = stations.id and favorites.favorable_type = 'Station'#{where} GROUP BY favorites.favorable_id, #{cols} ORDER BY favorites_count DESC LIMIT #{limit}"
  end
  
  def has_songs?
    songs.count > 0
  end
end
