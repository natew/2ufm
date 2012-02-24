require 'nokogiri'
require 'sanitize'
include AttachmentHelper
include PaperclipExtensions

class Post < ActiveRecord::Base  
  # Relationships
  belongs_to :blog
  has_many   :songs, :dependent => :destroy
  
  # Attachments
  has_attachment :image, styles: { original: ['300x300#'], medium: ['128x128#'], small: ['64x64#'] }
  
  acts_as_url :title, :url_attribute => :slug
  
  validates_uniqueness_of :url
  
  before_create :get_image
  after_create  :save_songs
  
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
    puts "Saving songs from post #{title}"
    parse = Nokogiri::HTML(content)
    parse.css('a').each do |link|
      if link['href'] =~ /.mp3/
        puts "Found song!"
        found_song = Song.create(
          :blog_id    => blog_id,
          :post_id    => id,
          :url        => link['href'],
          :link_text  => link.content,
          :created_at => created_at
        )
        puts "Created song #{link.content}"
      end
    end
  end
  handle_asynchronously :save_songs
end
