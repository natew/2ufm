require 'feedzirra'
require 'open-uri'
require 'nokogiri'
include AttachmentHelper

class Blog < ActiveRecord::Base  
  has_many   :songs
  has_many   :posts, :dependent => :destroy
  belongs_to :station
  
  acts_as_url :name, :url_attribute => :slug
  
  has_attachment :image, styles: { original: ['300x300#'], medium: ['128x128#'], small: ['64x64#'] }
  
  before_save   :get_blog_info
  after_create  :create_station, :get_feed_posts
  
  serialize :feed
  serialize :html
  
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
    set_correct_url
    get_html
    find_description
    find_feed_url
    update_feed
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
  
  def set_correct_url
    if url =~ /nahright.com/
      self.url = 'http://nahright.com/news/'
    end
  end
  
  def has_html?
    !html.nil?
  end
  
  def find_description
    if has_html?
      meta = html.at('meta[name="description"]')
      meta = meta['content'] unless meta.nil?
    end
    self.description = meta || html.at('title').text || ''
  end
  
  def find_feed_url
    self.feed_url = html.at('head > link[type="application/rss+xml"]')['href'] if has_html?
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
  
  def get_feed_posts
    feed.entries.each do |post|
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
  
  private
  
  def get_html
    self.html = Nokogiri::HTML(open(url))
    if html.nil?
      errors.add :url, 'No HTML found at url'
      false
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
  
  def create_station
    self.create_station(
      :name => name, 
      :description => description
    )
  end
end