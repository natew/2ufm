require 'nokogiri'

class Post < ActiveRecord::Base
  belongs_to :blog
  has_many  :songs, :dependent => :destroy
  
  before_create :set_excerpt
  after_create :save_songs
  
  acts_as_url :title, :url_attribute => :slug
  
  def to_param
    slug
  end
  
  def save_songs
    parse = Nokogiri::HTML(content)
    parse.css('a').each do |link|
      if link['href'] =~ /.mp3$/
        logger.info 'SAVING SONG  ' + link['href']
        Song.create!(:blog_id => blog_id, :post_id => id, :url => link['href'], :created_at => created_at)
      end
    end
  end

  def set_excerpt
    self.excerpt = ActionController::Base.helpers.strip_tags(content)[0,800]
  end
end
