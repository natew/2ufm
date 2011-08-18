require 'open-uri'
require 'mp3info'

class Song < ActiveRecord::Base
  belongs_to  :blog
  belongs_to  :post
  has_and_belongs_to_many :stations, :join_table => :stations_songs
  has_many :favorites, :as => :favorable
  has_many :files
  has_attached_file	:image,
  					:styles => {
  						:big      => ['256x256#', :jpg],
  						:medium   => ['128x128#', :jpg],
  						:small    => ['64x64#', :jpg],
  					},
            :path           => ':id_:style.:extension',
            :default_url    => '/images/song_default.jpg',
            :storage        => 's3',
            :s3_credentials => 'config/amazon_s3.yml',
            :bucket         => 'fm-song-images'
  
  acts_as_url :name, :url_attribute => :slug
  
  validates_presence_of :post_id, :blog_id
  
  after_create :set_info_and_save_to_station
  
  def to_param
    slug
  end
  
  def self.most_favorited(options = {})
    cols   = column_names.collect {|c| "songs.#{c}"}.join(",")
    within = options[:days] || 31
    limit  = options[:limit] || 12
    where  = " WHERE songs.created_at > '#{within.to_i.days.ago.to_s(:db)}'"
    
    Song.find_by_sql "SELECT songs.*, count(favorites.id) as favorites_count FROM songs INNER JOIN favorites on favorites.favorable_id = songs.id and favorites.favorable_type = 'Song'#{where} GROUP BY favorites.favorable_id, #{cols} ORDER BY favorites_count DESC LIMIT #{limit}"
  end
  
  private
  
  def set_similar
    clean_name = name.gsub(/[^A-Za-z0-9 ]/,'')
    clean_artist = artist.gsub(/[^A-Za-z0-9 ]/,'')
#    similar = Song.search(:name => clean_name).search(:artist => clean_artist).order('id ASC')
    
#    unless similar.empty?
#      self.shared_id = similar.first.id
#    else
#      self.shared_id = id
#    end
  end
  
  def set_info_and_save_to_station
    unless url.nil?
      begin
        open(url, :content_length_proc => lambda { |content_length|
          raise TooBig if content_length > (1048576 * 20) # 20 MB maximum song size
        }) { |song|
          Mp3Info.open(song.path) do |mp3|
            self.name = Sanitize.clean(mp3.tag.title)
            self.artist = Sanitize.clean(mp3.tag.artist)
            self.album = Sanitize.clean(mp3.tag.album)
            self.track_number = mp3.tag.tracknum.to_i
            self.genre = Sanitize.clean(mp3.tag.genre)
            self.bitrate = mp3.tag.bitrate.to_i
            self.length = mp3.tag.length.to_i
            
            # Set slug
            self.slug = name.to_url
            
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
      
      # Match with similar songs
      set_similar
      
      # Were done post-processing, so lets add it to the station
      self.blog.station.songs<<self
      
      self.save
    end
  end
  handle_asynchronously :set_info_and_save_to_station
end
