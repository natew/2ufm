require 'feedzirra'
require 'open-uri'
require 'nokogiri'
require 'anemone'

class Blog < ActiveRecord::Base
  include AttachmentHelper
  
  # Relationships
  has_one  :station, :dependent => :destroy
  has_many :songs, :through => :station, :dependent => :destroy
  has_many :posts, :dependent => :destroy
  has_and_belongs_to_many :genres

  # Slug
  acts_as_url :name, :url_attribute => :slug
  
  # Attachments
  has_attachment :image, styles: { original: ['300x300#'], medium: ['128x128#'], small: ['64x64#'] }
  
  before_create :make_station
  after_create  :delayed_get_blog_info, :delayed_fetch_new_posts
  
  serialize :feed
  
  # Validations
  validates :url, presence: true, uniqueness: true
  validates :name, presence: true, uniqueness: true
  validates_uniqueness_of :name, :url, :if => lambda { |o| o.current_step == "about" }
  validates_presence_of :name, :url, :if => lambda { |o| o.current_step == "about" }

  attr_writer :current_step

  # Whitelist mass-assignment attributes
  attr_accessible :name, :url, :description, :image, :feed_url
  
  def to_param
    slug
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
  
  # Search Nokogiri::HTML for a title or meta description
  def find_description(html)
    title = html.at('title')
    meta  = html.at('meta[type=description]')
    title ? title.text : (meta ? meta['content'] : nil)
  end

  # Search Nokogiri::HTML for an RSS feed
  def find_feed_url(html)
    feed  = html.at('head > link[type="application/rss+xml"]')
    feed ? feed['href'] : nil
  end

  # Get only new posts
  def fetch_new_posts
    entries = get_new_rss_entries!
    if entries
      entries.each do |post|
        # Search for song
        find_song_in(post.content) do
          logger.info "Creating post #{post.title}"
          # Save posts to db
          Post.create(
            :url => post.url.to_s,
            :blog_id => id,
            :title => post.title,
            :author => post.author,
            :content => post.content,
            :created_at => post.published
          )
        end
      end
    end
  end

  def delayed_fetch_new_posts
    if Rails.application.config.delay_jobs
      delay.fetch_new_posts
    else
      fetch_new_posts
    end
  end

  # Either fetches feed or updates feed 
  # Returns only new entries
  def get_new_rss_entries
    logger.info "Updating feed"
    if feed_url
      # Check if weve ever fetched feed
      if feed_updated_at
        # Already have feed, get new entries
        self.feed = Feedzirra::Feed.update(feed)
        self.feed_updated_at = feed.last_modified
        posts = feed.new_entries
      else
        # Get feed and return entries
        logger.info "No feed yet, grabbing rss"
        self.feed = Feedzirra::Feed.fetch_and_parse(feed_url)
        if feed
          logger.info "Found new entries"
          self.feed_updated_at = feed.last_modified
          posts = feed.entries
        else
          logger.error "No entries found"
          return false
        end
      end

      if !posts.blank?
        posts
      else
        logger.info "No new posts"
        false
      end
    end
  end

  # Gets a post based on URL
  def get_post_from_url(page_url)
    begin
      # Check if this url comes from this blog
      if URI(page_url).host =~ /#{URI(url).host}/
        Anemone.crawl(page_url) do |anemone|
          anemone.on_every_page do |page|
            save_page(page)
            return true # one page only
          end
        end
      else
        logger.error "URI does not match (#{URI(page_url).host} == #{URI(url).host})"
      end
    rescue Exception => e
      puts e.message
      puts e.backtrace.join("\n")
    end
  end

  def reset_feed
    self.feed = nil
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

  def find_song_in(content)
    html = Nokogiri::HTML(content)
    html.css('a').each do |link|
      if link['href'] =~ /\.mp3(\?(.*))?$/
        logger.info "Found song! #{link['href']}"
        yield html
        break
      end
    end
  end
  
  def make_station
    self.create_station
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