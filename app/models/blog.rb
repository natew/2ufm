require 'feedzirra'
require 'open-uri'
require 'nokogiri'

class Blog < ActiveRecord::Base
  has_many  :songs
  has_many  :posts, :dependent => :destroy
  has_one   :station
  
  before_create :create_station
  
  serialize :feed
  
  validates_uniqueness_of :name
  validates_presence_of :name
  
  acts_as_url :name, :url_attribute => :slug
  #acts_as_taggable
  
  has_attached_file	:image,
  					:styles => {
  						:big      => ['256x256#', :jpg],
  						:medium   => ['128x128#', :jpg],
  						:small    => ['64x64#', :jpg],
  					},
            :path           => ':id_:style.:extension',
            :default_url    => '/images/blog_default.jpg',
            :storage        => 's3',
            :s3_credentials => 'config/amazon_s3.yml',
            :bucket         => 'fm-blog-images'
  
  def to_param
    slug
  end
  
  def get_feed_url
    html = Nokogiri::HTML(open(url))
    self.feed_url = html.at('head > link[type="application/rss+xml"]')['href']
  end
  
  def update_feed
    get_feed_url if feed_url.nil? or feed_url.empty?
    if feed.nil? or feed.empty?
      self.feed = Feedzirra::Feed.fetch_and_parse(feed_url)
      #self.feed_updated_at = feed.last_modified
      self.save!
    else
      self.feed = Feedzirra::Feed.update(feed)
      #self.feed_updated_at = feed.last_modified
      self.save
      true if feed.updated?
      false
    end
  end
  
  def update_posts
    feed.entries.each do |post|
      # Save posts to db
      self.posts.create!(
          :title => post.title,
          :author => post.author,
          :url => post.url,
          :content => post.content,
          :created_at => post.published
        )
      
    end
  end
  
  private
  
  def create_station
    self.build_station(:name => name, :description => description)
  end
end
