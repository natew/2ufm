require 'feedzirra'

class Blog < ActiveRecord::Base
  has_many  :songs
  has_many  :posts
  
  serialize :feed
  
  validates_uniqueness_of :name
  validates_presence_of :name
  
  acts_as_url :name, :url_attribute => :slug
  
  def to_param
    slug
  end
end
