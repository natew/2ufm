require 'open-uri'
require 'mp3info'

class Song < ActiveRecord::Base
  belongs_to  :blog
  belongs_to  :post
  has_and_belongs_to_many :stations, :join_table => :stations_songs
  
  has_attached_file :apic
  
  after_create :set_id3
  
  validates_presence_of :post_id, :blog_id
  
  acts_as_url :name, :url_attribute => :slug
  acts_as_voteable
  
  def to_param
    slug
  end
  
  def set_id3
    unless url.nil?
      begin
        open(url, :content_length_proc => lambda { |content_length|
          raise TooBig if content_length > (1048576 * 10) # 10 MB maximum song size
        }) { |song|
          Mp3Info.open(song.path) do |mp3|
            self.name = mp3.tag.title
            self.artist = mp3.tag.artist
            self.album = mp3.tag.album
            self.track_number = mp3.tag.tracknum
            self.genre = mp3.tag.genre
            self.bitrate = mp3.tag.bitrate
            self.length = mp3.tag.length
            
            # Set slug
            self.slug = self.name.to_url
            
            # Save picture
          #  picture = mp3.tag2.APIC || mp3.tag2.PIC
          #  picture.gsub(/\x00[PNG|JPG|JPEG|GIF]\x00\x00/,'')
          #  
          #  unless picture.nil?
          #    pic_type = picture.match(/PNG|JPG|JPEG|GIF/)
          #    logger.info("pic_type = #{pic_type}")
          #    unless pic_type.nil?
          #      temp_path = "#{Rails.root}/tmp/apic_#{Process.pid}.#{pic_type[0]}"
          #      logger.info("temp_path = #{temp_path}")
          #      temp_pic = File.open(temp_path, 'wb') do |f|
          #        f.write(picture)
          #      end
                #Apic.create :song_id => id, :temp_path => temp_path, :filename => "#{artist}#{album}#{Process.pid}.#{pic_type[0]}"
          #    end
          #  end
          end
        }
      rescue TooBig
        self.artist = 'File Size Too Big!'
      end
      
      self.save
    end
  end
  handle_asynchronously :set_id3
end
