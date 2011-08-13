class Station < ActiveRecord::Base
  has_one :stations_songs
  has_and_belongs_to_many :songs, :join_table => :stations_songs
  belongs_to :user
  belongs_to :blog
  
  acts_as_url :name, :url_attribute => :slug
  acts_as_voteable
  acts_as_taggable
  
  validates_uniqueness_of :name
  validates_presence_of :name

  def to_param
    slug
  end
  
  def playlist  
    {
      :id     => id,
      :slug   => slug,
      :name   => name,
      :tracks => get_tracks
    }.to_json
  end
  
  def get_tracks
    songs.map do |s|
      { :id => "song-#{s.id}", :artist => s.artist, :name => s.name, :url => s.url }
    end
  end
  
  def has_songs?
    songs.count > 0
  end
end
