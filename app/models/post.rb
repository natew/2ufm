require 'nokogiri'
require 'sanitize'
include AttachmentHelper
include PaperclipExtensions

class Post < ActiveRecord::Base  
  belongs_to :blog
  has_many   :songs, :dependent => :destroy
  
  has_attachment :image, styles: { original: ['300x300#'], medium: ['128x128#'], small: ['64x64#'] }
  
  acts_as_url :title, :url_attribute => :slug
  
  before_create :get_image
  after_create :delayed_save_songs
  
  def to_param
    slug
  end
  
  def get_image
    post  = Nokogiri::HTML(content)
    img = post.css('img:first')
    if !img.empty?
      begin
        self.image = UrlTempfile.new(img.first['src'])
      rescue
        puts "Error downloading file"
      end
    end
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
  
  def delayed_save_songs
    delay.save_songs
  end
end
