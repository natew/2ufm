include AttachmentHelper
include PaperclipExtensions

class Artist < ActiveRecord::Base
  has_one    :station, :dependent => :destroy
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
      puts "Getting info for #{name}"
      info = DiscogsApi.get_artist(name)
      info = Hashie::Mash.new info
      puts "Info found" unless info.nil? or info.empty?
      self.image = UrlTempfile.new(info.images.first.uri) unless info.images.nil?
      self.urls  = info.urls unless info.urls.nil?
    rescue => exception
      # Artist not found!
      puts "Not found! #{exception.message}"
    end
  end
  
  def get_wikipedia_info
    if urls
      url = urls.find { |e| /^wikipedia/ =~ e }
      if url
        # get wikipedia url
      end
    end
  end
  
  protected
  
  def make_station
    self.create_station
  end
end
