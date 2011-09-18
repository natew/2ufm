require 'feedzirra'
require 'open-uri'
require 'nokogiri'

class Blog < ActiveRecord::Base
  include AttachmentHelper
  
  has_many   :songs, :extend => SongExtensions
  has_many   :posts, :dependent => :destroy

  acts_as_url :name, :url_attribute => :slug
  
  has_attachment :image, styles: { original: ['300x300#'], medium: ['128x128#'], small: ['64x64#'] }
  
  before_save   :get_blog_info
  after_create  :make_station, :get_new_posts
  
  serialize :feed
  
  attr_writer :current_step
  
  validates_uniqueness_of :name, :url
  validates_presence_of :name, :url
  
  def to_param
    slug
  end
  
  def has_blog_info?
    @blog_info || false
  end
  
  def get_blog_info
    get_html_info
    @blog_info = true
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
    !(feed_url.nil? or feed_url.empty?)
  end
  
  def update_feed
    if has_feed_url?
      if feed.nil?
        self.feed = Feedzirra::Feed.fetch_and_parse(feed_url)
        self.feed_updated_at = feed.last_modified
      else
        self.feed = Feedzirra::Feed.update(feed)
        self.feed_updated_at = feed.last_modified
      end
    end
  end
  
  def has_posts?
    posts.count > 0
  end
  
  def latest_post
    posts.order('created_at desc').limit(1).first
  end
  
  def get_new_posts
    if !feed.nil?
      update_feed
      last_post = latest_post if has_posts?
      feed.entries.each do |post|
        break if post.url == last_post.url
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
  
  private
  
#  def find_post_date(doc)
#    Chronic.parse(html.css('.entry-date,.date').to_s)
#  end
#  
#  def find_google_date(url)
#    doc = Nokogiri::HTML(open("http://google.com/search?q=inurl:#{url}"))
#    Chronic.parse(doc.at('#ires span.f.std').text)
#  end

  def make_station
    self.station_id = Station.create(:name => name).id
  end
end