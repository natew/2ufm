class Station < ActiveRecord::Base
  has_one :stations_songs
  has_and_belongs_to_many :songs, :join_table => :stations_songs
  belongs_to :user
  belongs_to :blog
  has_many   :favorites, :as => :favorable
  
  acts_as_url :name, :url_attribute => :slug
  
  validates_uniqueness_of :name
  validates_presence_of :name
  
  has_attached_file	:image,
  					:styles => {
  						:original => ['300x300#', :jpg],
  						:medium   => ['128x128#', :jpg],
  						:small    => ['64x64#', :jpg],
  					},
            :path           => ':id_:style.:extension',
            :default_url    => '/images/station_default.jpg',
            :storage        => 's3',
            :s3_credentials => 'config/amazon_s3.yml',
            :bucket         => 'fm-station-images'

  def to_param
    slug
  end
  
  def image_or_parent(*types)
    type = types[0] || 'original'
    image if image.present?
    if blog_id
      "http://#{image.s3_host_name}/#{image.bucket_name}/#{blog_id}_#{type}.jpg"
    else
      image
    end
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
