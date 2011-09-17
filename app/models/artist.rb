include AttachmentHelper

class Artist < ActiveRecord::Base
  belongs_to :station
  has_many   :authors
  has_many   :songs, :through => :authors, :extend => SongExtensions
  
  acts_as_url :name, :url_attribute => :slug
  
  has_attachment :image, styles: { original: ['300x300#'], medium: ['128x128#'], small: ['64x64#'] }
            
  before_create :make_station
  
  validates :name, presence: true, allow_blank: false
  
  def to_param
    slug
  end
  
  protected
  
  def make_station
    self.station_id = Station.create(:name => name).id
  end
end
