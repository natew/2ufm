class Artist < ActiveRecord::Base
  has_many  :songs
  has_many  :albums
  
  acts_as_url :title, :url_attribute => :slug
  
  def to_param
    slug
  end
end
