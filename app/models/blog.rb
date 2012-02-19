require 'feedzirra'
require 'open-uri'
require 'nokogiri'

class Blog < ActiveRecord::Base
  include AttachmentHelper
  
  has_one  :station, :dependent => :destroy
  has_many :songs, :through => :station, :dependent => :destroy
  has_many :posts, :dependent => :destroy
  has_and_belongs_to_many :genres

  acts_as_url :name, :url_attribute => :slug
  
  has_attachment :image, styles: { original: ['300x300#'], medium: ['128x128#'], small: ['64x64#'] }
  
  before_save   :get_blog_info
  before_create :make_station
  after_create  :get_new_posts
  
  default_scope where(working:true)
  
  serialize :feed
  
  attr_writer :current_step
  
  validates_uniqueness_of :name, :url, :if => lambda { |o| o.current_step == "about" }
  validates_presence_of :name, :url, :if => lambda { |o| o.current_step == "about" }
  
  def to_param
    slug
  end
  
  def has_blog_info?
    working
  end
  
  def get_blog_info
    get_html_info
    updated = update_feed
    self.working = true if updated
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
      meta = html.at('meta[name="description"]')
      meta = meta['content'] unless meta.nil?
      self.description = meta || html.at('title').text
      self.feed_url = html.at('head > link[type="application/rss+xml"]')['href']
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

  # Either fetches feed or updates feed 
  # Returns only new entries
  def update_feed
    if has_feed_url?
      if feed_updated_at.blank?
        self.feed = Feedzirra::Feed.fetch_and_parse(feed_url)
        if feed != 0
          self.feed_updated_at = feed.last_modified
          return feed.entries
        else
          return false
        end
      else
        self.feed = Feedzirra::Feed.update(feed)
        self.feed_updated_at = feed.last_modified
        return feed.new_entries
      end
    end
  end
  
  # Scans feed and adds new posts
  def get_new_posts
    if !feed.nil?
      entries = update_feed
      if !entries.blank?
        entries.each do |post|
          # Save posts to db
          self.posts.create(
            :title => post.title,
            :author => post.author,
            :url => post.url,
            :content => post.content,
            :created_at => post.published
          )
        end
      end
    end
  end
  handle_asynchronously :get_new_posts if Rails.env.production?
  
  private
  
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