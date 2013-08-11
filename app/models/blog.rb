# require 'feedzirra'
require 'open-uri'
require 'nokogiri'
require 'anemone'
require 'rss'

class Blog < ActiveRecord::Base
  include AttachmentHelper
  include SlugExtensions

  # Relationships
  has_one  :station, :dependent => :destroy
  has_many :songs, :dependent => :destroy
  has_many :posts, :dependent => :destroy
  has_and_belongs_to_many :genres

  # Slug
  acts_as_url :name, :url_attribute => :slug

  # Attachments
  has_attachment :image, styles: { medium: ['256x256#'], small: ['128x128#'], small: ['64x64#'] }

  after_create  :delayed_get_blog_info, :delayed_get_new_posts, :delayed_set_screenshot
  before_create :make_station, :set_station_slug

  # Validations
  validates :url, presence: true, uniqueness: true
  validates :name, presence: true, uniqueness: true
  validates_with SlugValidator

  # Whitelist mass-assignment attributes
  attr_accessible :name, :url, :description, :image, :feed_url, :genre_ids, :active, :email, :slug, :genre_ids

  # Scopes
  scope :select_for_shelf, -> { select('blogs.name, blogs.slug, blogs.image_file_name, blogs.image_updated_at, blogs.id') }
  scope :random, -> { order('random() desc') }

  rails_admin do
    configure :genres do
      inverse_of :blogs

      associated_collection_cache_all true
      associated_collection_scope do
        Proc.new { |scope|
          scope = scope.where(active: true)
        }
      end
    end

    edit do
      field :name
      field :active
      field :url
      field :feed_url
      field :image
      field :genres
    end

    list do
      field :id
      field :name
      field :feed_updated_at
    end
  end

  def to_param
    station_slug
  end

  def get_title
    name
  end

  def station_songs_count
    station.songs_count
  end

  # Uses Anemone to crawl a website
  #     http://anemone.rubyforge.org/
  #     http://anemone.rubyforge.org/doc/index.html
  def crawl
    return unless active
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
        Post.create(
          url: page.url.to_s,
          blog_id: id,
          title: title,
          author: '',
          content: html,
          published_at: Date.parse(page.headers['date'][0])
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

  def set_screenshot(delay=0)
    # Hit bitpixels once to get them to take the shot, will return blank file
    open("http://img.bitpixels.com/getthumbnail?code=61978&size=200&url=#{url}")
    sleep(delay)
    file = open("http://img.bitpixels.com/getthumbnail?code=61978&size=200&url=#{url}")
    self.image = file
    self.save
  end

  def delayed_set_screenshot
    # Wait before getting real screenshot
    delay.set_screenshot(60)
  end

  # Search Nokogiri::HTML for a title or meta description
  def find_description(html)
    title = html.at('title')
    meta  = html.at('meta[type=description]')
    title ? (title.respond_to?(:text) ? title.text : title) : (meta ? meta['content'] : nil)
  end

  # Search Nokogiri::HTML for an RSS feed
  def find_feed_url(html)
    feed = html.at('head > link[type="application/rss+xml"]')
    feed ? feed['href'] : nil
  end

  # Get only new posts
  def get_new_posts
    return unless active
    save_posts(get_new_rss_entries)
  end

  def delayed_get_new_posts
    return unless active
    if Rails.application.config.delay_jobs
      delay(:priority => 5).get_new_posts
    else
      get_new_posts
    end
  end

  def rescan_posts_within(time)
    posts.within(time).each do |post|
      post.delayed_save_songs
    end
  end

  def save_posts(entries)
    if entries
      entries.each do |post|
        Post.create(
          url: post.link.to_s,
          blog_id: id,
          title: post.title,
          author: post.author,
          content: post.content_encoded,
          published_at: post.pubDate
        )
      end
    end
  end

  # Returns only new entries
  def get_new_rss_entries
    return unless active
    if feed_url
      logger.info "Updating feed for #{name}"
      posts = []

      open(feed_url) do |rss|
        begin
          logger.info rss
          feed = RSS::Parser.parse(rss, false).channel
        rescue Exception => e
          logger.error e
          logger.error "Error parsing feed"
        end

        date = feed.lastBuildDate || feed.pubDate
        return unless feed
        # return unless date > self.feed_updated_at
        logger.debug "Feed updated! at #{date}"
        
        feed.items.each do |entry|
          logger.info entry.inspect
          # break if entry.pubDate < feed_updated_at
          posts.push entry
        end

        self.feed_updated_at = date
        self.save
        logger.debug "Found #{posts.length} posts"
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

  def make_station
    self.create_station(title:name)
  end

  def get_relevant_genres
    get_song_genres.limit(6)
  end

  def get_song_genres
    songs.joins(:genres).where('song_genres.source != ?', 'blog').group('genres.name').select('count(genres.name) as genre_count, genres.name as genre_name').order('genre_count desc')
  end

  def song_genres
    map_genres_with_counts(get_song_genres)
  end

  def relevant_genres
    map_genres_with_counts(get_relevant_genres)
  end

  def map_genres_with_counts(genres)
    genres.map { |s| [s.genre_name, s.genre_count.to_i] }
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
      if link['href'] =~ /soundcloud\.com\/.*\/|\.mp3(\?(.*))?$/
        logger.info "Found song! #{link['href']}"
        yield html
      end
    end

    html.css('iframe').each do |iframe|
      if iframe['src'] =~ /soundcloud\.com.*tracks|youtube.com\/embed/
        logger.info "Found music iframe! #{iframe['src']}"
        yield html
      end
    end
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