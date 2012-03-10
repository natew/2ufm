require 'feedzirra'
require 'open-uri'
require 'nokogiri'
require 'anemone'

class Blog < ActiveRecord::Base
  include AttachmentHelper
  
  has_one  :station, :dependent => :destroy
  has_many :songs, :through => :station, :dependent => :destroy
  has_many :posts, :dependent => :destroy
  has_and_belongs_to_many :genres

  acts_as_url :name, :url_attribute => :slug
  
  has_attachment :image, styles: { original: ['300x300#'], medium: ['128x128#'], small: ['64x64#'] }
  
  before_create :make_station
  after_create  :delayed_get_blog_info
  
  scope :working, where(working:true)
  
  serialize :feed
  
  attr_writer :current_step
  
  validates_uniqueness_of :name, :url, :if => lambda { |o| o.current_step == "about" }
  validates_presence_of :name, :url, :if => lambda { |o| o.current_step == "about" }
  
  def to_param
    slug
  end

  def crawl
    puts "Crawling #{name}"
    begin
      Anemone.crawl(fetch_url) do |anemone|
        anemone.storage = Anemone::Storage.MongoDB
        anemone.on_every_page do |page|
          puts "Crawling #{page.url} (#{page.code})"
          if page.code == 200
            headers_date = Date.parse(page.headers['date'][0])
            html = Nokogiri::HTML(page.body)
            html.css('a').each do |link|
              if link['href'] =~ /\.mp3(\?(.*))?$/
                puts "Found song! #{link['href']}"
                post = Post.find_or_create_by_url(
                    :url => page.url.to_s,
                    :blog_id => id,
                    :title => html.at('title').text || meta['content'] || '',
                    :author => '',
                    :content => page.body,
                    :published_at => headers_date
                  )
                break
              end
            end
          end
        end
      end
    rescue => exception
      puts exception.inspect
      puts exception.backtrace
    end
  end

  def delayed_crawl
    if Rails.application.config.delay_jobs
      delay(:priority => 3).crawl
    else
      crawl
    end
  end
  
  def has_blog_info?
    working
  end
  
  def get_blog_info
    get_html_info
    self.working = true if get_new_posts
    self.save
  end

  def delayed_get_blog_info
    if Rails.application.config.delay_jobs
      delay.get_blog_info
    else
      get_blog_info
    end
  end
  
  def reset
    posts.destroy
    feed = nil
    get_blog_info
    get_new_posts
    true if self.save
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
  
  # Gets the description and RSS
  def get_html_info
    begin
      html = Nokogiri::HTML(open(url))
    rescue
      errors.add :url, 'Error accessing website'
      return false
    end
    
    if html.nil?
      errors.add :url, 'Nothing found!'
      return false
    else
      self.description = html.at('title') ? html.at('title').text : ''

      feed  = html.at('head > link[type="application/rss+xml"]')
      self.feed_url = feed ? feed['href'] : nil
    end
  end
  
  def has_feed_url?
    !feed_url.blank?
  end
  
  def has_posts?
    posts.count > 0
  end
  
  def latest_post
    posts.order('created_at desc').first
  end

  def reset_feed
    self.feed = nil
    self.feed_updated_at = nil
    self.save
  end

  # Either fetches feed or updates feed 
  # Returns only new entries
  def update_feed
    puts "Updating feed"
    if has_feed_url?
      if feed_updated_at.blank?
        puts "No feed yet, grabbing rss"
        self.feed = Feedzirra::Feed.fetch_and_parse(feed_url)
        if feed != 0
          puts "Found new entries"
          self.feed_updated_at = feed.last_modified
          return feed.entries
        else
          puts "No entries found"
          return false
        end
      else
        self.feed = Feedzirra::Feed.update(feed)
        self.feed_updated_at = feed.last_modified
        puts "Done"
        return feed.new_entries
      end
    end
  end

  def update_feed_and_save
    update_feed
    self.save
  end
  
  # Get only new posts
  def get_new_posts
    entries = update_feed
    if !entries.blank?
      get_posts(entries)
    else
      puts "No new posts"
      false
    end
  end

  # Will get posts, regarless of new or not
  def get_posts(entries)
    entries.each do |post|
      # Save posts to db
      self.posts.create(
        :title => post.title,
        :author => post.author,
        :url => post.url,
        :content => post.content,
        :created_at => post.published
      )
      puts "Created post #{post.title}"
      true
    end
  end
  
  private

  def fetch_url
    final_uri = ''
    open(url) do |h|
      final_uri = h.base_uri
    end
    final_uri
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