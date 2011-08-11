require 'feedzirra'

class Blog < ActiveRecord::Base
  has_many  :songs
  has_many  :posts
  
  serialize :feed
end
