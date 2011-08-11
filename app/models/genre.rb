class Genre < ActiveRecord::Base
  acts_as_url :title, :url_attribute => :slug
  
  def to_param
    slug
  end
end
