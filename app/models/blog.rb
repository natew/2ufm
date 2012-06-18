require 'feedzirra'
require 'open-uri'
require 'nokogiri'
require 'anemone'

class Blog < ActiveRecord::Base
  include AttachmentHelper

  # Relationships
  has_one  :station, :dependent => :destroy
  has_many :songs, :dependent => :destroy
  has_many :posts, :dependent => :destroy
  has_and_belongs_to_many :genres

  # Slug
  acts_as_url :name, :url_attribute => :slug

  # Attachments
  has_attachment :image, styles: { original: ['300x300#'], medium: ['128x128#'], small: ['64x64#'] }

  after_create  :delayed_get_blog_info, :delayed_get_new_posts
  before_create :make_station, :set_screenshot

  # Validations
  validates :url, presence: true, uniqueness: true
  validates :name, presence: true, uniqueness: true
  validates_with SlugValidator

  attr_writer :current_step

  # Whitelist mass-assignment attributes
  attr_accessible :name, :url, :description, :image, :feed_url

  # Scopes
  scope :select_for_shelf, select('blogs.name, blogs.slug, blogs.image_file_name, blogs.image_updated_at, blogs.id')

  def to_param
    slug
  end

  def get_title
    name
  end

  # Uses Anemone to crawl a website
  #     http://anemone.rubyforge.org/
  #     http://anemone.rubyforge.org/doc/index.html
  def crawl
    logger.info "Crawling #{name}"
    pages = 0
    self.crawl_started_at = Time.now
    begin
      Anemone.crawl(fetch_url(url)) do |anemone|
        anemone.storage = Anemone::Storage.MongoDB
        anemone.on_every_page do |page|
          pages += 1
          save_page(page)
        end
      end
      self.crawl_finished_at = Time.now
      self.crawled_pages = pages
      self.save
    rescue => exception
      logger.error exception.inspect
      logger.error exception.backtrace
    end
  end

  # Use delayed_job to run the crawl function
  def delayed_crawl
    if Rails.application.config.delay_jobs
      delay(:priority => 3).crawl
    else
      crawl
    end
  end

  def crawl_page(url)
    begin
      Anemone.crawl(fetch_url(url)) do |anemone|
        anemone.focus_crawl { |page| nil }
        anemone.on_every_page do |page|
          puts page
          save_page(page)
        end
      end
    rescue
    end
  end

  # Given an Anemone::Page, save as a post if it finds an MP3 file
  #     Anemone::Page http://anemone.rubyforge.org/doc/classes/Anemone/Page.html
  def save_page(page)
    logger.info "Processing #{page.url} (#{page.code})"
    if page.code == 200
      find_song_in(page.body) do |html|
        title = find_description(html)
        logger.info "Creating post #{title} (#{page.url})"
        post = Post.create(
            :url => page.url.to_s,
            :blog_id => id,
            :title => title,
            :author => '',
            :content => page.body,
            :published_at => Date.parse(page.headers['date'][0])
          )
      end
    else
      logger.error "Page header response is not 200"
    end
  end

  # Saves description and feed
  def get_blog_info
    html = get_html(url)
    if html
      self.description = find_description(html)
      self.feed_url = find_feed_url(html)
      self.save
    else
      errors.add :url, 'Nothing found at url!'
    end
  end

  def delayed_get_blog_info
    if Rails.application.config.delay_jobs
      delay.get_blog_info
    else
      get_blog_info
    end
  end

  def set_screenshot
    file = open "http://img.bitpixels.com/getthumbnail?code=61978&size=200&url=#{url}"
    self.image = file
  end

  # Search Nokogiri::HTML for a title or meta description
  def find_description(html)
    title = html.at('title')
    meta  = html.at('meta[type=description]')
    title ? title.text : (meta ? meta['content'] : nil)
  end

  # Search Nokogiri::HTML for an RSS feed
  def find_feed_url(html)
    feed = html.at('head > link[type="application/rss+xml"]')
    feed ? feed['href'] : nil
  end

  # Get only new posts
  def get_new_posts
    save_posts(get_new_rss_entries)
  end

  def delayed_get_new_posts
    if Rails.application.config.delay_jobs
      delay.get_new_posts
    else
      get_new_posts
    end
  end

  def save_posts(entries)
    if entries
      entries.each do |post|
        logger.info "Searching for songs in #{post.title}"
        # Search for song
        find_song_in(post.content) do
          logger.info "Found song, creating post #{post.title}"
          # Save posts to db
          Post.create(
            :url => post.url.to_s,
            :blog_id => id,
            :title => post.title,
            :author => post.author,
            :content => post.content,
            :published_at => post.published
          )
        end
      end
    end
  end

  # Returns only new entries
  def get_new_rss_entries
    if feed_url
      logger.info "Updating feed for #{name}"
      posts = []
      feed = Feedzirra::Feed.fetch_and_parse(feed_url)

      if feed and !feed.is_a?(Fixnum)
        if feed_updated_at.nil? or feed.last_modified > feed_updated_at
          logger.debug "Feed updated at: #{feed_updated_at}"
          feed.entries.each do |entry|
            logger.debug "Break? #{entry.published}: #{entry.published < feed_updated_at}" unless feed_updated_at.nil?
            break if !feed_updated_at.nil? and entry.published < feed_updated_at
            posts.push entry
          end
          self.feed_updated_at = feed.last_modified
          self.save
          logger.debug "Found #{posts.length} posts"
        end
      else
        logger.error "Error fetching feed / no entries found #{feed}"
      end

      posts.empty? ? false : posts
    else
      logger.error "No feed url"
      false
    end
  end

  # Gets a post based on URL
  def get_post(url)
    begin
      # Check if this url comes from this blog
      if URI(url).host =~ /#{URI(url).host}/
        Anemone.crawl(url) do |anemone|
          anemone.on_every_page do |page|
            save_page(page)
            return true # one page only
          end
        end
      else
        logger.error "URI does not match (#{URI(url).host} == #{URI(url).host})"
      end
    rescue Exception => e
      logger.info e.message
      logger.info e.backtrace.join("\n")
    end
  end

  def reset_feed
    self.feed_updated_at = nil
    self.save
  end

  def reset
    posts.destroy
    feed = nil
    get_blog_info
    self.save
  end

  def has_posts?
    posts.count > 0
  end

  def latest_post
    posts.order('created_at desc').first
  end

  def current_step
    @current_step || steps.first
  end

  def steps
    %w[about info verify]
  end

  def next_step
    self.current_step = steps[steps.index(current_step)+1]
  end

  def previous_step
    self.current_step = steps[steps.index(current_step)-1]
  end

  def first_step?
    current_step == steps.first
  end

  def last_step?
    current_step == steps.last
  end

  def step_index
    steps.index(current_step)+1
  end

  def all_valid?
    steps.all? do |step|
      self.current_step = step
      valid?
    end
  end

  private

  def get_html(url)
    begin
      Nokogiri::HTML(open(url))
    rescue
      logger.error "Error opening url #{url}"
      false
    end
  end

  def fetch_url(url)
    final_uri = url
    open(url) do |h|
      final_uri = h.base_uri
    end
    final_uri
  end

  def find_song_in(content)
    html = Nokogiri::HTML(content)
    html.css('a').each do |link|
      logger.debug "Checking link #{link['href']}"
      if link['href'] =~ /\.mp3(\?(.*))?$/
        logger.info "Found song! #{link['href']}"
        yield html
        break
      end
    end

    html.css('iframe').each do |iframe|
      if iframe['src'] =~ /soundcloud\.com.*tracks/
        logger.info "Found soundcloud iframe! #{iframe['src']}"
        yield html
        break
      end
    end
  end

  def make_station
    self.create_station(title:name)
  end

#  def find_post_date(doc)
#    Chronic.parse(html.css('.entry-date,.date').to_s)
#  end
#
#  def find_google_date(url)
#    doc = Nokogiri::HTML(open("http://google.com/search?q=inurl:#{url}"))
#    Chronic.parse(doc.at('#ires span.f.std').text)
#  end
end