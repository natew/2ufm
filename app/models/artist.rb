class Artist < ActiveRecord::Base
  has_and_belongs_to_many  :songs
  belongs_to :station
  
  acts_as_url :name, :url_attribute => :slug
  
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
            :bucket         => 'fm-artist-images'
            
  before_create :create_station
  
  def to_param
    slug
  end
  
  protected
  
  def create_station
    self.create_station(:name => name)
  end
end
