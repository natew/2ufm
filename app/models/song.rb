require 'open-uri'
require 'mp3info'

class Song < ActiveRecord::Base  
  belongs_to  :blog
  belongs_to  :post
  belongs_to  :artist
  has_many    :broadcasts, :dependent => :destroy
  has_many    :stations, :through => :broadcasts
  
  has_attached_file	:image,
  					:styles => {
  						:original => ['300x300#', :jpg],
  						:medium   => ['128x128#', :jpg],
  						:small    => ['64x64#', :jpg],
  					},
            :path           => ':id_:style.:extension',
            :default_url    => '/images/default_:style.jpg',
            :storage        => 's3',
            :s3_credentials => 'config/amazon_s3.yml',
            :bucket         => 'fm-song-images'
            
  default_scope includes(:post)
  
  acts_as_url :full_name_and_id, :url_attribute => :slug
  
  validates_presence_of :post_id, :blog_id
  
  before_save  :clean_url
  after_create :delayed_scan_and_save, :add_to_stations
  
  def to_param
    slug
  end
  
  def full_name
    "#{artist_name} - #{name}"
  end
  
  def full_name_and_id
    "#{full_name} #{id}"
  end
  
  def is_popular?
    favorites.where('created at > ?', 10.days.ago).count > 10
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
  
  def scan_and_save
    unless url.nil?
      begin
        total = nil
        open(URI.escape(url),
          :content_length_proc => lambda { |content_length|
            raise TooBig if content_length > (1048576 * 20) # 20 MB maximum song size
            total = content_length
          },
          :progress_proc => lambda { |at|
            #puts "DOWNLOADING #{(at.fdiv(total)*100).round}%"
          }
        ) do |song|
          Mp3Info.open(song.path) do |mp3|
            # Read from ID3
            self.name = mp3.tag.title
            self.artist_name = mp3.tag.artist
            self.album_name = mp3.tag.album
            self.track_number = mp3.tag.tracknum.to_i
            self.genre = mp3.tag.genre
            self.bitrate = mp3.tag.bitrate.to_i
            self.length = mp3.tag.length.to_f
            
            # If the ID3 doenst help us
            if !name or !artist_name
              self.processed = parse_from_link
            else
              self.processed = true
            end
            
            # Save picture
            picture = mp3.tag2.APIC || mp3.tag2.PIC
            picture = picture[0] if picture.is_a? Array
            if picture
              picture.gsub(/\x00[PNG|JPG|JPEG|GIF]\x00\x00/,'')
              pic_type = picture.match(/PNG|JPG|JPEG|GIF/)
              if pic_type
                tmp_path = "#{Rails.root}/tmp/albumart/apic_#{Process.pid}.#{pic_type[0]}"
                tmp_file = File.open(tmp_path, 'wb') do |f|
                  f.write(picture[6,picture.length])  # yikes
                end
                self.image = tmp_file
              end
            end
            
            # Update info if we have processed this song
            if processed?
              find_similar_songs
              find_or_create_artist
              self.slug = full_name_and_id.to_url
            end
            
            # Done
            self.save
          end
        end
      rescue Exception => e
        logger.info(e.message + "\n" + e.backtrace.inspect)
      end
    end
  end
  
  def delayed_scan_and_save
    delay.scan_and_save
  end
  
  private
  
  def parse_from_link
    split = link_text.split(/\s*-\s*/)
    if split.size == 2
      self.artist_name = split[0]
      self.name = split[1]
      true
    else
      false
    end
  end
  
  def clean_url
    self.url = URI.escape(url)
  end
  
  def add_to_new_station
    Station.new_songs.songs<<self unless Station.new_songs.song_exists?(id)
  end
  
  def find_or_create_artist
    artist = Artist.where("name ILIKE (?)", search_artist).limit(1).first
    
    if artist
      self.artist_id = artist.id
    else
      build_artist(:name => artist)
    end
  end
  
  def add_to_stations
    add_to_new_station
    if self.blog and !self.blog.station.song_exists?(id)
      self.blog.station.songs<<self
    end
  end
  
  def matching_songs
    if name and artist_name
      Song.where("artist_name ILIKE (?) and name ILIKE(?)", search_artist, search_name)
    else
      []
    end
  end
  
  def find_similar_songs
    most_similar = matching_songs.first
    
    if most_similar
      self.shared_id = most_similar.id
    else
      self.shared_id = id
    end
  end
  
  def search_name
    clean(name)
  end
  
  def search_artist
    clean(artist_name)
  end
  
  def clean(attr)
    attr.gsub(/[()']/,'%').gsub(/( mix| remix|feat |ft |original mix|radio edit|extended edit|extended version| RMX|vip mix|vip edit)*|/i,'').strip unless attr.nil?
  end
end
