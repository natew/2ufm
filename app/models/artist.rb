require 'discogs'

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

  validates :name, presence: true, uniqueness: true, allow_blank: false

  def to_param
    slug
  end

  def get_info
    get_discogs_info
    get_wikipedia_info
  end

  def get_discogs_info
    begin
      logger.info "Getting info for #{name}"
      wrapper = Discogs::Wrapper.new("fusefm")
      artist = wrapper.get_artist(name)

      if !artist.nil?
        logger.info "Info found"
        self.image = UrlTempfile.new(artist.images.first.uri) unless artist.images.nil?
        self.urls  = artist.urls unless artist.urls.nil?
      else
        logger.info "No information found"
      end
    rescue Exception => e
      # Artist not found!
      logger.info "Error!"
      logger.info e.message
      logger.info e.backtrace
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
    self.create_station(title:name)
  end
end
