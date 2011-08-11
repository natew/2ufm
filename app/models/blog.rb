require 'feedzirra'
require 'open-uri'
require 'nokogiri'

class Blog < ActiveRecord::Base
  has_many  :songs, :dependent => :destroy
  has_many  :posts, :dependent => :destroy
  
  serialize :feed
  
  validates_uniqueness_of :name
  validates_presence_of :name
  
  acts_as_url :name, :url_attribute => :slug
  
  def to_param
    slug
  end
  
  def get_feed_url
    html = Nokogiri::HTML(open(url))
    self.feed = html.at('head > link[type = "application/rss+xml"]')['href']
    self.save
  end
  
  def update_feed
    get_feed_url if feed_url.nil?
    if feed.nil?
      self.feed = Feedzirra::Feed.fetch_and_parse(feed_url)
      self.feed_updated_at = feed.last_modified
      self.save!
    else
      self.feed = Feedzirra::Feed.update(feed)
      self.feed_updated_at = feed.last_modified
      self.save
      true if feed.updated
      false
    end
  end
  
  def update_posts
    feed.each do |post|
      # Save posts to db
      posts.create(
          :title => post.title,
          :author => post.author,
          :url => post.url,
          :content => post.content,
          :created_at => post.published
        )
    end
  end
end
