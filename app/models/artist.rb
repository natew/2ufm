include AttachmentHelper

class Artist < ActiveRecord::Base
  belongs_to :station
  has_many   :authors
  has_many   :songs, :through => :authors do
    def to_playlist
      self.map do |s|
        {:id => s.id, :artist => s.artist_name, :name => s.name, :url => s.url } if s.processed?
      end.compact.to_json
    end
  end
  
  acts_as_url :name, :url_attribute => :slug
  
  has_attachment :image, styles: { original: ['300x300#'], medium: ['128x128#'], small: ['64x64#'] }
            
  before_create :generate_station
  
  validates :name, presence: true, allow_blank: false
  
  def to_param
    slug
  end
  
  protected
  
  def generate_station
    self.create_station(name: name)
  end
end
