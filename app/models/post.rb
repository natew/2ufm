require 'nokogiri'

class Post < ActiveRecord::Base
  belongs_to :blog
  has_many  :songs
  
  def save_songs
    parse = Nokogiri::HTML(content)
    parse.css('a').each do |link|
      if link['href'] =~ /.mp3$/
        logger.info 'SAVING SONG  ' + link['href']
        song = Song.new(:blog_id => blog_id, :post_id => id, :url => link['href'])
        if song.save!
          song.save_id3
        else
          logger.info 'Error saving song'
        end
      end
    end
  end
end
