require 'nokogiri'

class Post < ActiveRecord::Base
  belongs_to :blog
  has_many  :songs
  
  acts_as_url :title, :url_attribute => :slug
  
  def to_param
    slug
  end
  
  def save_songs
    parse = Nokogiri::HTML(content)
    parse.css('a').each do |link|
      if link['href'] =~ /.mp3$/
        logger.info 'SAVING SONG  ' + link['href']
        song = Song.new(:blog_id => blog_id, :post_id => id, :url => link['href'])
        song.save
      end
    end
  end
end
