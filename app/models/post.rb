require 'nokogiri'
require 'sanitize'

class Post < ActiveRecord::Base
  belongs_to :blog
  
  has_many  :songs, :dependent => :destroy do
    def processed
      self.where('songs.processed = true')
    end
  end
  
  acts_as_url :title, :url_attribute => :slug
  
  after_create :save_songs
  
  def to_param
    slug
  end
  
  def excerpt
    ActionController::Base.helpers.strip_tags(content)[0,300]
  end
  
  def save_songs
    parse = Nokogiri::HTML(content)
    parse.css('a').each do |link|
      if link['href'] =~ /.mp3/
        Song.create!(
          :blog_id    => blog_id,
          :post_id    => id,
          :url        => link['href'],
          :link_text  => link.content,
          :created_at => created_at
        )
      end
    end
  end
  handle_asynchronously :save_songs
end
