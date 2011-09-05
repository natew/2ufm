class Station < ActiveRecord::Base
  has_and_belongs_to_many :genres
  belongs_to :user
  belongs_to :blog
  has_many   :favorites, :as => :favorable
  
  has_and_belongs_to_many :songs do
    def to_playlist
      self.map do |s|
        {:id => s.id, :artist => s.artist, :name => s.name, :url => s.url } if s.processed?
      end.compact.to_json
    end
  end
  
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
            :default_url    => '/images/default_:style.jpg',
            :storage        => 's3',
            :s3_credentials => 'config/amazon_s3.yml',
            :bucket         => 'fm-station-images'

  def to_param
    slug
  end
  
  def self.most_favorited(options = {})
    cols   = column_names.collect {|c| "stations.#{c}"}.join(",")
    within = options[:days] || 31
    limit  = options[:limit] || 12
    where  = " WHERE stations.created_at > '#{within.to_i.days.ago.to_s(:db)}'"
    
    Station.find_by_sql "SELECT stations.*, count(favorites.id) as favorites_count FROM stations INNER JOIN favorites on favorites.favorable_id = stations.id and favorites.favorable_type = 'Station'#{where} GROUP BY favorites.favorable_id, #{cols} ORDER BY favorites_count DESC LIMIT #{limit}"
  end
  
  def image_or_parent(*types)
    type = types[0] || 'original'

    if image.file?
      image(type)
    elsif blog and blog.image.file?
      blog.image(type)
    elsif user and user.image.file?
      user.image(type)
    else
      image(type)
    end
  end
  
  def has_songs?
    songs.count > 0
  end
end
