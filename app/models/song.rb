require 'open-uri'
require 'mp3info'
require 'texticle'
ActiveRecord::Base.extend(Texticle)

class Song < ActiveRecord::Base  
  belongs_to  :blog
  belongs_to  :post
  has_and_belongs_to_many :stations
  has_many :favorites, :as => :favorable
  has_many :files
  has_attached_file	:image,
  					:styles => {
  						:original => ['300x300#', :jpg],
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
  
  after_create :scan
  
  def to_param
    slug
  end
  
  def processed?
    processed
  end
  
  def full_name
    "#{artist} &mdash; #{name}".html_safe
  end
  
  def self.most_favorited(options = {})
    cols   = column_names.collect {|c| "songs.#{c}"}.join(",")
    within = options[:days] || 31
    limit  = options[:limit] || 12
    where  = " WHERE songs.created_at > '#{within.to_i.days.ago.to_s(:db)}' AND songs.processed = true"
    
    Song.find_by_sql "SELECT songs.*, count(favorites.id) as favorites_count FROM songs INNER JOIN favorites on favorites.favorable_id = songs.id and favorites.favorable_type = 'Song'#{where} GROUP BY favorites.favorable_id, #{cols} ORDER BY favorites_count DESC LIMIT #{limit}"
  end
  
  def add_to_user_stations
    # users = Favorite.joins(:user).select('favorites.user_id, users.station_id').where(:favorable_type => 'Song', :favorable_id => 4)
    #     users.each do |user|
    #       StationsSongs.create(:song_id => id, :station_id => user.station_id)
    #     end
  end
  
  def set_similar
    most_similar = Song.search_by_name_and_artist(name, artist).limit(1)
   
    if most_similar.rank.to_f > 0.3
      self.shared_id = most_similar.id
    else
      self.shared_id = id
    end
  end
  
  def search_by_name_and_artist(name, artist)
    clean_name = name.gsub(/[^A-Za-z0-9 ]/,'')
    clean_artist = artist.gsub(/[^A-Za-z0-9 ]/,'')
    Song.where('name ilike ? and artist ilike ?',clean_name,clean_artist)
  end
  
  def scan
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
            self.length = (mp3.tag.length*1000).to_i
            
            # Set slug
            self.slug = name.to_url
            
            # Save picture
            picture = mp3.tag2.APIC || mp3.tag2.PIC
            picture.gsub(/\x00[PNG|JPG|JPEG|GIF]\x00\x00/,'')
            
            unless picture.nil?
              pic_type = picture.match(/PNG|JPG|JPEG|GIF/)
              unless pic_type.nil?
                tmp_path = "#{Rails.root}/tmp/albumart/apic_#{Process.pid}.#{pic_type[0]}"
                tmp_file = File.open(tmp_path, 'wb') do |f|
                  f.write(picture[6,1000000000000])  # yikes
                end
                self.image = tmp_file
              end
            end
          end
        }
      rescue Exception => e
        logger.info(e.message + "\n" + e.backtrace.inspect)
      end
      
      # Match with similar songs
      set_similar
      
      # Were done post-processing, so lets add it to the station
      self.blog.station.songs<<self
      
      self.processed = true
      self.save
    end
  end
  handle_asynchronously :scan
end
