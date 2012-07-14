require 'discogs'

class Artist < ActiveRecord::Base
  include AttachmentHelper
  include PaperclipExtensions
  include SlugExtensions

  has_one    :station, :dependent => :destroy
  has_many   :broadcasts, :through => :songs
  has_many   :stations, :through => :broadcasts
  has_many   :authors
  has_many   :songs, :through => :authors, :extend => SongExtensions

  acts_as_url :name, :url_attribute => :slug, :allow_duplicates => false

  has_attachment :image, styles: { original: ['300x300#'], medium: ['128x128#'], small: ['64x64#'] }

  before_validation :make_station, :on => :create
  after_create :get_info

  serialize :urls

  validates :name, presence: true, uniqueness: true
  validates :station, presence: true
  validates_with SlugValidator

  scope :for_linking, joins(:authors).select('artists.id, artists.slug, artists.name, authors.role as role')

  def to_param
    station_slug
  end

  def to_playlist_json
    self.to_json(:only => [:id, :slug, :name])
  end

  def get_title
    name
  end

  # returns station slug
  def url
    station.slug
  end

  def get_info
    delay(:priority => 6).get_discogs_info
  end

  def get_discogs_info
    begin
      logger.info "Getting info for #{name}"
      wrapper = Discogs::Wrapper.new("fusefm")
      artist  = wrapper.get_artist(name)

      if !artist.nil?
        logger.info "Info found"
        self.image = UrlTempfile.new(artist.images.first.uri) unless artist.images.nil?
        self.urls  = artist.urls unless artist.urls.nil?
        self.save
      else
        logger.info "No information found"
      end
    rescue Exception => e
      # Artist not found!
      logger.error "Error getting discogs information."
    end
  end

  def make_station
    self.create_station(title:name)
  end
end
