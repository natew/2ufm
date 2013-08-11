require 'nokogiri'
include AttachmentHelper
include PaperclipExtensions

class Post < ActiveRecord::Base
  belongs_to :blog
  has_many   :songs, :dependent => :destroy

  has_attachment :image, :s3 => Yetting.s3_enabled, styles: { medium: ['256x256#'], small: ['128x128#'], icon: ['64x64#'] }

  validates :url, presence: true, uniqueness: true

  acts_as_url :title, :url_attribute => :slug, :allow_duplicates => false

  before_create :get_image, :get_content, :set_excerpt
  after_create :delayed_save_songs

  attr_accessible :title, :url, :blog_id, :author, :content, :published_at, :excerpt

  scope :within, lambda { |within| where('posts.published_at >= ?', within.ago) }

  rails_admin do
    list do
      field :id
      field :title
      field :url
      field :blog
    end
  end

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

  def get_content
    if !content
      open(url) do |f|
        self.content = f.read
      end
    else
      content
    end
  end

  def save_songs
    logger.info "Saving songs from post #{title}"
    parse = Nokogiri::HTML(get_content)
    parse.css('a').each do |link|
      if link['href'] =~ /soundcloud\.com\/.*\// # /soundcloud\.com\/.*\/|\.mp3(\?(.*))?$/
        logger.info "Found song!"
        found_song = create_song(link['href'],link.content)
      end
    end

    parse.css('iframe').each do |iframe|
      if iframe['src'] =~ /soundcloud\.com.*tracks/ # |youtube.com\/embed/
        logger.info "Found music iframe!"
        found_song = create_song(iframe['src'], '')
      end
    end
  end

  def create_song(url, text)
    song = Song.find_by_url(url)
    unless song
      Song.create(
        blog_id: blog_id,
        post_id: id,
        url: url,
        link_text: text,
        published_at: created_at
      )
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
