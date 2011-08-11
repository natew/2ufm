require 'open-uri'
require 'mp3info'

class Song < ActiveRecord::Base
  belongs_to  :blog
  belongs_to  :post
  
  has_attached_file :apic
  
  def save_id3
    unless url.nil?
      song = open(url)
      Mp3Info.open(song.path) do |mp3|
        self.name = mp3.tag.title
        self.artist = mp3.tag.artist
        self.album = mp3.tag.album
        self.track_number = mp3.tag.tracknum
        self.genre = mp3.tag.genre
        self.bitrate = mp3.tag.bitrate
        
        picture = mp3.tag2.APIC || mp3.tag2.PIC
        picture.gsub(/\x00[PNG|JPG|JPEG|GIF]\x00\x00/,'')
        logger.info("picture = #{picture}")
        
        unless picture.nil?
          pic_type = picture.match(/PNG|JPG|JPEG|GIF/)
          logger.info("pic_type = #{pic_type}")
          unless pic_type.nil?
            temp_path = "#{Rails.root}/tmp/apic_#{Process.pid}.#{pic_type[0]}"
            logger.info("temp_path = #{temp_path}")
            temp_pic = File.open(temp_path, 'wb') do |f|
              f.write(picture)
            end
            #Apic.create :song_id => id, :temp_path => temp_path, :filename => "#{artist}#{album}#{Process.pid}.#{pic_type[0]}"
          end
        end
        
        self.save
      end
    end
  end
  #handle_asynchronously :save_id3
end
