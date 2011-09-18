include AttachmentHelper

class Artist < ActiveRecord::Base
  belongs_to :station
  has_many   :authors
  has_many   :songs, :through => :authors, :extend => SongExtensions
  
  acts_as_url :name, :url_attribute => :slug
  
  has_attachment :image, styles: { original: ['300x300#'], medium: ['128x128#'], small: ['64x64#'] }
            
  before_create :make_station, :get_info
  
  serialize :urls
  
  validates :name, presence: true, allow_blank: false
  
  def to_param
    slug
  end
  
  def get_info
    get_discogs_info
    get_wikipedia_info
  end
  
  def get_discogs_info
    begin
      info = DiscogsApi.get_artist(name)
      info = Hashie::Mash.new info
      self.image = URLTempfile.new(info.images.first.uri) unless info.images.nil?
      self.urls  = info.urls unless info.urls.nil?
    rescue
      # Artist not found!
    end
  end
  
  def get_wikipedia_info
    url = urls.find { |e| /^wikipedia/ =~ e } unless urls.nil?
    url = '' # get wikipedia url
      
  end
  
  protected
  
  def make_station
    self.station_id = Station.create(:name => name).id
  end
end
