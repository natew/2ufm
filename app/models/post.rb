require 'nokogiri'
include AttachmentHelper
include PaperclipExtensions

class Post < ActiveRecord::Base
  # Relationships
  belongs_to :blog
  has_many   :songs, :dependent => :destroy

  # Attachments
  has_attachment :image, styles: { original: ['300x300#'], medium: ['128x128#'], small: ['64x64#'] }

  # Validations
  validates :url, presence: true, uniqueness: true

  # Slug
  acts_as_url :title, :url_attribute => :slug

  before_create :get_image
  before_save :set_excerpt
  after_create  :delayed_save_songs

  # Whitelist mass-assignment attributes
  attr_accessible :title, :url, :blog_id, :author, :content, :published_at

  def to_param
    slug
  end

  def set_excerpt
    begin
      self.excerpt = Sanitize.clean(content).truncate(200)
    rescue
      logger.error "No excerpt"
      self.excerpt = "No content"
    end
  end

  def get_image
    logger.info "Getting image"
    begin
      post  = Nokogiri::HTML(content)
      img = post.css('img:first')
      self.image = UrlTempfile.new(img.first['src']) unless img.empty?
    rescue => exception
      logger.error exception.message
      logger.error exception.backtrace
    end
  end

  def save_songs
    logger.info "Saving songs from post #{title}"
    parse = Nokogiri::HTML(content)
    parse.css('a').each do |link|
      if link['href'] =~ /\.mp3(\?(.*))?$/
        logger.info "Found song!"
        #TODO Find or create by ID so we can rescan posts
        found_song = Song.create(
          :blog_id    => blog_id,
          :post_id    => id,
          :url        => link['href'],
          :link_text  => link.content,
          :published_at => created_at
        )
        logger.info "Created song #{link.content}"
      end
    end
  end

  def process_songs
    songs.each do |song|
      logger.info "Processing song #{song.url}"
      song.scan_and_save
    end
  end

  def delayed_save_songs
    if Rails.application.config.delay_jobs
      delay(:priority => 2).save_songs
    else
      save_songs
    end
  end
end
