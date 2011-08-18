class Album < ActiveRecord::Base
  belongs_to :artist
  
  acts_as_url :title, :url_attribute => :slug
  
  def to_param
    slug
  end
end
